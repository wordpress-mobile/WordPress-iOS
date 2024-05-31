import UIKit
import Combine
import WordPressFlux

enum EditMode {
    case richText
    case html

    mutating func toggle() {
        switch self {
        case .richText:
            self = .html
        case .html:
            self = .richText
        }
    }
}

typealias EditorViewController = UIViewController & PostEditor
typealias ReplaceEditorCallback = (EditorViewController, EditorViewController) -> ()

/// Common interface to all editors
///
protocol PostEditor: PublishingEditor, UIViewControllerTransitioningDelegate {

    /// The post being edited.
    ///
    var post: AbstractPost { get set }

    /// Initializer
    ///
    /// - Parameters:
    ///     - post: the post to edit. Must be already assigned to a `ManagedObjectContext` since
    ///     that's necessary for the edits to be saved.
    ///     - replaceEditor: a closure that handles switching from one editor to another
    ///     - editorSession: post editor analytics session
    init(
        post: AbstractPost,
        replaceEditor: @escaping ReplaceEditorCallback,
        editorSession: PostEditorAnalyticsSession?)

    /// Media items to be inserted on the post after creation
    ///
    /// - Parameter media: the media items to add
    ///
    func prepopulateMediaItems(_ media: [Media])

    /// Cancels all ongoing uploads
    ///
    func cancelUploadOfAllMedia(for post: AbstractPost)

    /// Whether the editor has failed media or not
    ///
    var hasFailedMedia: Bool { get }

    var isUploadingMedia: Bool { get }

    /// Verification prompt helper
    var verificationPromptHelper: VerificationPromptHelper? { get }

    /// Post editor state context
    var postEditorStateContext: PostEditorStateContext { get }

    /// Update editor UI with given html
    func setHTML(_ html: String)

    /// Return the current html in the editor
    func getHTML() -> String

    /// Title of the post
    var postTitle: String { get set }

    /// Describes the editor type to be used in analytics reporting
    var analyticsEditorSource: String { get }

    /// Error domain used when reporting error to Crash Logger
    var errorDomain: String { get }

    /// Navigation bar manager for this post editor
    var navigationBarManager: PostEditorNavigationBarManager { get }

    /// Editor Session information for analytics reporting
    var editorSession: PostEditorAnalyticsSession { get set }

    /// Closure to call when the editor needs to be replaced with a different editor
    /// First argument is the existing editor, second argument is the replacement editor
    var replaceEditor: ReplaceEditorCallback { get }

    var autosaver: Autosaver { get set }

    /// true if the post is the result of a reblog
    var postIsReblogged: Bool { get set }

    /// From where the editor was shown (for analytics reporting)
    var entryPoint: PostEditorEntryPoint { get set }
}

extension PostEditor {

    var editorHasContent: Bool {
        return post.hasContent()
    }

    var editorHasChanges: Bool {
        if FeatureFlag.syncPublishing.enabled {
            return !post.changes.isEmpty
        } else {
            return post.hasUnsavedChanges()
        }
    }

    func editorContentWasUpdated() {
        postEditorStateContext.updated(hasContent: editorHasContent)
        postEditorStateContext.updated(hasChanges: editorHasChanges)
    }

    var mainContext: NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    var currentBlogCount: Int {
        return postIsReblogged ? BlogQuery().hostedByWPCom(true).count(in: mainContext) : Blog.count(in: mainContext)
    }

    var alertBarButtonItem: UIBarButtonItem? {
        return navigationBarManager.closeBarButtonItem
    }

    var prepublishingSourceView: UIView? {
        return navigationBarManager.publishButton
    }
}

extension PostEditor where Self: UIViewController {
    func onViewDidLoad() {
        guard FeatureFlag.syncPublishing.enabled else {
            return
        }

        if post.original().status == .trash {
            showPostTrashedOverlay()
        } else {
            showAutosaveAvailableAlertIfNeeded()
            showTerminalUploadErrorAlertIfNeeded()
        }

        var cancellables: [AnyCancellable] = []

        NotificationCenter.default
            .publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.appWillTerminate()
            }.store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: .postConflictResolved)
            .sink { [weak self] notification in
                self?.postConflictResolved(notification)
            }.store(in: &cancellables)

        objc_setAssociatedObject(self, &cancellablesKey, cancellables, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    // MARK: - Autosave

    private func showAutosaveAvailableAlertIfNeeded() {
        // The revision has unsaved local changes, takes precedence over autosave
        guard post.changes.isEmpty else {
            return // Do nothing
        }
        guard post.hasAutosaveRevision, let autosaveDate = post.autosaveModifiedDate else {
            return
        }
        showAutosaveAvailableAlert(autosaveDate: autosaveDate)
    }

    private func showAutosaveAvailableAlert(autosaveDate: Date) {
        let alert = UIAlertController(title: Strings.autosaveAlertTitle, message: Strings.autosaveAlertMessage(date: autosaveDate), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.autosaveAlertContinue, style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.createRevisionOfPost(loadAutosaveRevision: true)
            self.post = self.post // Reload UI
        }))
        alert.addAction(UIAlertAction(title: Strings.autosaveAlertCancel, style: .cancel, handler: nil))
        present(alert, animated: true)
    }

    // MARK: - App Termination

    private func appWillTerminate() {
        guard let context = post.managedObjectContext else {
            return
        }
        // Defensive code to make sure that in rare scenarios where the user changes
        // status from post settings but doesn't save, and the app gets terminated,
        // the app doesn't end up saving posts with uncommited status changes.
        if post.status != post.original().status {
            post.status = post.original().status
        }
        if post.changes.isEmpty {
            AbstractPost.deleteLatestRevision(post, in: context)
        } else {
            if FeatureFlag.autoSaveDrafts.enabled, PostCoordinator.shared.isSyncAllowed(for: post) {
                PostCoordinator.shared.setNeedsSync(for: post)
            } else {
                EditPostViewController.encode(post: post)
            }
        }
        if context.hasChanges {
            ContextManager.sharedInstance().saveContextAndWait(context)
        }
    }

    // MARK: - Conflict Resolution

    private func postConflictResolved(_ notification: Foundation.Notification) {
        guard
            let userInfo = notification.userInfo,
            let post = userInfo[PostCoordinator.NotificationKey.postConflictResolved] as? AbstractPost
        else {
            return
        }
        self.configureWithUpdatedPost(post)
    }

    // MARK: - Restore Trashed Post

    private func showPostTrashedOverlay() {
        let overlay = PostTrashedOverlayView()
        view.addSubview(overlay)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.onOverlayTapped = { [weak self] in self?.showRestorePostAlert(with: $0) }
        view.pinSubviewToAllEdges(overlay)
    }

    private func showRestorePostAlert(with overlay: PostTrashedOverlayView) {
        overlay.isUserInteractionEnabled = false

        let postType = post.localizedPostType.lowercased()
        let alert = UIAlertController(title: String(format: Strings.trashedPostSheetTitle, postType), message: String(format: Strings.trashedPostSheetMessage, postType), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.trashedPostSheetCancel, style: .cancel) { _ in
            overlay.isUserInteractionEnabled = true
        })
        alert.addAction(UIAlertAction(title: Strings.trashedPostSheetRecover, style: .default) { [weak self] _ in
            guard let self else { return }
            Task {
                await self.restorePostFromTrash()
            }
        })
        present(alert, animated: true)
    }

    @MainActor
    private func restorePostFromTrash() async {
        SVProgressHUD.show()
        defer { SVProgressHUD.dismiss() }
        let coordinator = PostCoordinator.shared
        do {
            try await coordinator.restore(post)
            ActionDispatcher.dispatch(NoticeAction.post(Notice(title: Strings.trashedPostRestored)))
            self.configureWithUpdatedPost(post)
        } catch {
            coordinator.handleError(error, for: post)
        }
    }

    private func configureWithUpdatedPost(_ post: AbstractPost) {
        self.post = post // Even if it's the same instance, it's how you currently refresh the editor
        self.createRevisionOfPost()
    }

    // MARK: - Failed Media Uploads

    private func showTerminalUploadErrorAlertIfNeeded() {
        let hasTerminalError = post.media.contains {
            guard let error = $0.error else { return false }
            return MediaCoordinator.isTerminalError(error)
        }
        if hasTerminalError {
            let notice = Notice(title: Strings.failingMediaUploadsMessage, feedbackType: .error, actionTitle: Strings.failingMediaUploadsViewAction, actionHandler: { [weak self] _ in
                self?.showMediaUploadDetails()
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(700)) {
                ActionDispatcherFacade().dispatch(NoticeAction.post(notice))
            } // Delay to let the editor show first
        }
    }

    private func showMediaUploadDetails() {
        let viewController = PostMediaUploadsViewController(post: post)
        let nav = UINavigationController(rootViewController: viewController)
        nav.navigationBar.isTranslucent = true // Reset to default
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        })
        if let sheetController = nav.sheetPresentationController {
            sheetController.detents = [.medium(), .large()]
            sheetController.prefersGrabberVisible = true
            sheetController.preferredCornerRadius = 16
            nav.additionalSafeAreaInsets = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        }
        self.present(nav, animated: true)
    }
}

private var cancellablesKey: UInt8 = 0

enum PostEditorEntryPoint: String {
    case unknown
    case postsList
    case pagesList
    case dashboard
    case bloggingPromptsFeatureIntroduction = "blogging_prompts_introduction"
    case bloggingPromptsActionSheetHeader = "add_new_sheet_answer_prompt"
    case bloggingPromptsNotification = "blogging_reminders_notification_answer_prompt"
    case bloggingPromptsDashboardCard = "my_site_card_answer_prompt"
    case bloggingPromptsListView = "blogging_prompts_list_view"
}

private enum Strings {
    static let autosaveAlertTitle = NSLocalizedString("autosaveAlert.title", value: "Autosave Available", comment: "An alert suggesting to load autosaved revision for a published post")

    static func autosaveAlertMessage(date: Date) -> String {
        let format = NSLocalizedString("autosaveAlert.message", value: "You've made unsaved changes to this post from a different device. Edited: %@.", comment: "An alert suggesting to load autosaved revision for a published post")
        return String(format: format, date.mediumStringWithTime())
    }

    static let autosaveAlertContinue = NSLocalizedString("autosaveAlert.viewChanges", value: "View Changes", comment: "An alert suggesting to load autosaved revision for a published post")
    static let autosaveAlertCancel = NSLocalizedString("autosaveAlert.cancel", value: "Cancel", comment: "An alert suggesting to load autosaved revision for a published post")

    static let trashedPostSheetTitle = NSLocalizedString("postEditor.recoverTrashedPostAlert.title", value: "Trashed %@", comment: "Editor, alert for recovering a trashed post")
    static let trashedPostSheetMessage = NSLocalizedString("postEditor.recoverTrashedPostAlert.message", value: "A trashed %1$@ can't be edited. To edit this %1$@, you'll need to restore it by moving it back to a draft.", comment: "Editor, alert for recovering a trashed post")
    static let trashedPostSheetCancel = NSLocalizedString("postEditor.recoverTrashedPostAlert.cancel", value: "Cancel", comment: "Editor, alert for recovering a trashed post")
    static let trashedPostSheetRecover = NSLocalizedString("postEditor.recoverTrashedPostAlert.restore", value: "Restore", comment: "Editor, alert for recovering a trashed post")
    static let trashedPostRestored = NSLocalizedString("postEditor.recoverTrashedPost.postRecoveredNoticeTitle", value: "Post restored as a draft", comment: "Editor, notice for successful recovery a trashed post")

    static let failingMediaUploadsMessage = NSLocalizedString("postEditor.postHasFailingMediaUploadsSnackbar.message", value: "Some media items failed to upload", comment: "A message for a snackbar informing the user that some media files requires their attention")

    static let failingMediaUploadsViewAction = NSLocalizedString("postEditor.postHasFailingMediaUploadsSnackbar.actionView", value: "View", comment: "A 'View' action for a snackbar informing the user that some media files requires their attention")
}

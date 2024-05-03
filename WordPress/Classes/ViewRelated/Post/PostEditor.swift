import UIKit
import Combine

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
    ///     - loadAutosaveRevision: if true, apply autosave content when the editor creates a revision.
    ///     - replaceEditor: a closure that handles switching from one editor to another
    ///     - editorSession: post editor analytics session
    init(
        post: AbstractPost,
        loadAutosaveRevision: Bool,
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

    var prepublishingIdentifiers: [PrepublishingIdentifier] {
        PrepublishingIdentifier.defaultIdentifiers
    }
}

extension PostEditor where Self: UIViewController {
    func onViewDidLoad() {
        guard FeatureFlag.syncPublishing.enabled else {
            return
        }
        showAutosaveAvailableAlertIfNeeded()

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

    private func postConflictResolved(_ notification: Foundation.Notification) {
        guard
            let userInfo = notification.userInfo,
            let post = userInfo[PostCoordinator.NotificationKey.postConflictResolved] as? AbstractPost
        else {
            return
        }
        self.post = post
        createRevisionOfPost()
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
}

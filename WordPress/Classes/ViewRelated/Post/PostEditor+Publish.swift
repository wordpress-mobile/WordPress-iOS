import Foundation
import WordPressFlux
import WordPressUI
import WordPressShared

protocol PublishingEditor where Self: UIViewController {
    var post: AbstractPost { get set }

    var isUploadingMedia: Bool { get }

    /// Post editor state context
    var postEditorStateContext: PostEditorStateContext { get }

    /// Editor Session information for analytics reporting
    var editorSession: PostEditorAnalyticsSession { get set }

    /// Verification prompt helper
    var verificationPromptHelper: VerificationPromptHelper? { get }

    /// Describes the editor type to be used in analytics reporting
    var analyticsEditorSource: String { get }

    /// Title of the post
    var postTitle: String { get set }

    var alertBarButtonItem: UIBarButtonItem? { get }

    /// Closure to be executed when the editor gets closed.
    var onClose: ((_ changesSaved: Bool) -> Void)? { get set }

    /// Return the current html in the editor
    func getHTML() -> String

    /// Returns the word counts of the content in the editor.
    var wordCount: UInt { get }

    /// Debouncer used to save the post locally with a delay
    var debouncer: Debouncer { get }

    func emitPostSaveEvent()

    // TODO: rework how the editors manage their changes
    var editorHasContent: Bool { get }

    var editorHasChanges: Bool { get }
}

extension PublishingEditor {
    func emitPostSaveEvent() {
        // Default implementation is empty, can be optionally implemented by other classes.
    }

    // The debouncer will perform this callback every 500ms in order to save the post locally with a delay.
    var debouncerCallback: (() -> Void) {
        return { [weak self] in
            guard let self = self else {
                return
            }
            if self.post.hasChanges {
                guard let context = self.post.managedObjectContext else {
                    return
                }
                ContextManager.sharedInstance().save(context)
            }
        }
    }

    func handlePrimaryActionButtonTap() {
        performEditorAction(postEditorStateContext.action, analyticsStat: postEditorStateContext.publishActionAnalyticsStat)
    }

    func buttonSaveDraftTapped() {
        WPAnalytics.track(.editorPostSaveDraftTapped)
        mapUIContentToPostAndSave(immediate: true)
        guard !isUploadingMedia else {
            return displayMediaIsUploadingAlert()
        }
        performUpdateAction(analyticsStat: .editorSavedDraft)
    }

    func performEditorAction(_ action: PostEditorAction, analyticsStat: WPAnalyticsStat?) {
        if action == .publish {
            WPAnalytics.track(.editorPostPublishTap)
        }

        mapUIContentToPostAndSave(immediate: true)

        switch action {
        case .publish:
            showPublishingConfirmation(for: action, analyticsStat: analyticsStat)
        case .update:
            guard !isUploadingMedia else {
                return displayMediaIsUploadingAlert()
            }
            performUpdateAction(analyticsStat: .editorUpdatedPost)
        case .submitForReview:
            guard !isUploadingMedia else {
                return displayMediaIsUploadingAlert()
            }
            var changes = RemotePostUpdateParameters()
            changes.status = Post.Status.pending.rawValue
            performUpdateAction(changes: changes, analyticsStat: .editorPublishedPost)
        }
    }

    private func showPublishingConfirmation(for action: PostEditorAction, analyticsStat: WPAnalyticsStat?) {
        PrepublishingViewController.show(for: post, from: self) { [weak self] result in
            guard let self else { return }
            switch result {
            case .published:
                self.emitPostSaveEvent()
                if let analyticsStat {
                    self.trackPostSave(stat: analyticsStat)
                }
                self.editorSession.end(outcome: action.analyticsEndOutcome)

                let presentBloggingReminders = JetpackNotificationMigrationService.shared.shouldPresentNotifications()
                self.dismissOrPopView(presentBloggingReminders: presentBloggingReminders)
            case .cancelled:
                WPAnalytics.track(.editorPostPublishDismissed)
            }
        }
    }

    private func performSaveDraftAction() {
        PostCoordinator.shared.setNeedsSync(for: post)
        dismissOrPopView()
    }

    private func performUpdateAction(changes: RemotePostUpdateParameters? = nil, analyticsStat: WPAnalyticsStat) {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()
        postEditorStateContext.updated(isBeingPublished: true)

        Task { @MainActor in
            do {
                let post = try await PostCoordinator.shared.save(post, changes: changes)
                self.post = post
                self.createRevisionOfPost()
                self.trackPostSave(stat: analyticsStat)
            } catch {
                postEditorStateContext.updated(isBeingPublished: false)
            }
            await SVProgressHUD.dismiss()
        }
    }

    func displayMediaIsUploadingAlert() {
        let alertController = UIAlertController(title: MediaUploadingAlert.title, message: MediaUploadingAlert.message, preferredStyle: .alert)
        alertController.addDefaultActionWithTitle(MediaUploadingAlert.acceptTitle)
        present(alertController, animated: true, completion: nil)
    }

    private func trackPostSave(stat: WPAnalyticsStat) {
        let postTypeValue = post is Page ? "page" : "post"

        guard stat != .editorSavedDraft && stat != .editorQuickSavedDraft else {
            WPAppAnalytics.track(stat, withProperties: [WPAppAnalyticsKeyEditorSource: analyticsEditorSource, WPAppAnalyticsKeyPostType: postTypeValue], with: post.blog)
            return
        }

        let wordCount = self.wordCount
        var properties: [String: Any] = ["word_count": wordCount, WPAppAnalyticsKeyEditorSource: analyticsEditorSource]

        properties[WPAppAnalyticsKeyPostType] = postTypeValue

        if stat == .editorPublishedPost {
            properties[WPAnalyticsStatEditorPublishedPostPropertyCategory] = post.hasCategories()
            properties[WPAnalyticsStatEditorPublishedPostPropertyPhoto] = post.hasPhoto()
            properties[WPAnalyticsStatEditorPublishedPostPropertyTag] = post.hasTags()
            properties[WPAnalyticsStatEditorPublishedPostPropertyVideo] = post.hasVideo()

            if let post = post as? Post, let promptId = post.bloggingPromptID {
                properties["prompt_id"] = promptId
            }
        }

        WPAppAnalytics.track(stat, withProperties: properties, with: post)
    }

    // MARK: - Close button handling

    func cancelEditing() {
        ActionDispatcher.dispatch(NoticeAction.clearWithTag(uploadFailureNoticeTag))
        stopEditing()

        guard editorHasChanges && editorHasContent else {
            return discardAndDismiss()
        }

        if post.original().isStatus(in: [.draft, .pending]) {
            // The "Discard Changes" behavior is problematic due to the way
            // the editor and `PostCoordinator` often update the content
            // in the background without the user interaction.
            showCloseDraftConfirmationAlert()
        } else {
            showClosePublishedPostConfirmationAlert()
        }
    }

    private func discardAndDismiss() {
        editorSession.end(outcome: .cancel)
        discardUnsavedChangesAndUpdateGUI()
    }

    func discardUnsavedChangesAndUpdateGUI() {
        let postDeleted = discardChanges()
        dismissOrPopView(didSave: !postDeleted)
    }

    @discardableResult
    func discardChanges() -> Bool {
        guard post.status != .trash else {
            return true // No revision is created for trashed posts
        }

        guard let context = post.managedObjectContext else {
            wpAssertionFailure("Missing managedObjectContext")
            return true
        }

        WPAppAnalytics.track(.editorDiscardedChanges, withProperties: [WPAppAnalyticsKeyEditorSource: analyticsEditorSource], with: post)

        // Cancel upload of only newly inserted media items
        if let previous = post.original {
            for media in post.media.subtracting(previous.media) {
                DDLogInfo("post-editor: cancel upload for \(media.filename ?? media.description)")
                MediaCoordinator.shared.cancelUpload(of: media)
            }
        } else {
            wpAssertionFailure("the editor must be working with a revision")
        }

        AbstractPost.deleteLatestRevision(post, in: context)
        ContextManager.shared.saveContextAndWait(context)
        return true
    }

    private func showCloseDraftConfirmationAlert() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.view.accessibilityIdentifier = "post-has-changes-alert"
        alert.addCancelActionWithTitle(Strings.closeConfirmationAlertCancel)
        let discardTitle = post.original().isNewDraft ? Strings.closeConfirmationAlertDelete : Strings.closeConfirmationAlertDiscardChanges
        alert.addDestructiveActionWithTitle(discardTitle) { _ in
            self.discardAndDismiss()
        }
        alert.addActionWithTitle(Strings.closeConfirmationAlertSaveDraft, style: .default) { _ in
            self.performSaveDraftAction()
        }
        alert.popoverPresentationController?.barButtonItem = alertBarButtonItem
        present(alert, animated: true, completion: nil)
    }

    private func showClosePublishedPostConfirmationAlert() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.view.accessibilityIdentifier = "post-has-changes-alert"
        alert.addCancelActionWithTitle(Strings.closeConfirmationAlertCancel)
        alert.addDestructiveActionWithTitle(Strings.closeConfirmationAlertDiscardChanges) { _ in
            self.discardAndDismiss()
        }
        alert.popoverPresentationController?.barButtonItem = alertBarButtonItem
        present(alert, animated: true, completion: nil)
    }
}

extension PublishingEditor {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?) -> UIPresentationController? {
        guard presented is FancyAlertViewController else {
            return nil
        }

        return FancyAlertPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

// MARK: - Publishing

extension PublishingEditor {
    func dismissOrPopView(didSave: Bool = true, presentBloggingReminders: Bool = false) {
        stopEditing()

        WPAppAnalytics.track(.editorClosed, withProperties: [WPAppAnalyticsKeyEditorSource: analyticsEditorSource], with: post)

        if let onClose = onClose {
            // if this closure exists, the presentation of the Blogging Reminders flow (if needed)
            // needs to happen in the closure.
            onClose(didSave)
        } else if isModal(), let controller = presentingViewController {
            controller.dismiss(animated: true) {
                if presentBloggingReminders {
                    BloggingRemindersFlow.present(from: controller,
                                                  for: self.post.blog,
                                                  source: .publishFlow,
                                                  alwaysShow: false)
                }
            }
        } else {
            navigationController?.popViewController(animated: true)
            guard let controller = navigationController?.topViewController else {
                return
            }

            if presentBloggingReminders {
                BloggingRemindersFlow.present(from: controller,
                                              for: self.post.blog,
                                              source: .publishFlow,
                                              alwaysShow: false)
            }
        }
    }

    func stopEditing() {
        view.endEditing(true)
    }

    func mapUIContentToPostAndSave(immediate: Bool = false) {
        post.postTitle = postTitle
        post.content = getHTML()
        debouncer.call(immediate: immediate)
    }

    func createRevisionOfPost(loadAutosaveRevision: Bool = false) {
        guard let managedObjectContext = post.managedObjectContext else {
            return wpAssertionFailure("managedObjectContext is missing")
        }

        wpAssert(post.latest() == post, "Must be opened with the latest verison of the post")

        if !post.isUnsavedRevision && post.status != .trash {
            DDLogDebug("Creating new revision")
            post = post.createRevision()
        }

        if loadAutosaveRevision {
            DDLogDebug("Loading autosave")
            post.postTitle = post.autosaveTitle
            post.mt_excerpt = post.autosaveExcerpt
            post.content = post.autosaveContent
            post = post // Update the UI
        }

        ContextManager.sharedInstance().save(managedObjectContext)
    }

    var uploadFailureNoticeTag: Notice.Tag {
        return "PostEditor.UploadFailed"
    }
}

struct PostEditorDebouncerConstants {
    static let autoSavingDelay = Double(7.0)
}

private enum Strings {
    static let closeConfirmationAlertCancel = NSLocalizedString("postEditor.closeConfirmationAlert.keepEditing", value: "Keep Editing", comment: "Button to keep the changes in an alert confirming discaring changes")
    static let closeConfirmationAlertDelete = NSLocalizedString("postEditor.closeConfirmationAlert.discardDraft", value: "Discard Draft", comment: "Button in an alert confirming discaring a new draft")
    static let closeConfirmationAlertDiscardChanges = NSLocalizedString("postEditor.closeConfirmationAlert.discardChanges", value: "Discard Changes", comment: "Button in an alert confirming discaring changes")
    static let closeConfirmationAlertSaveDraft = NSLocalizedString("postEditor.closeConfirmationAlert.saveDraft", value: "Save Draft", comment: "Button in an alert confirming saving a new draft")
}

private struct MediaUploadingAlert {
    static let title = NSLocalizedString("Uploading media", comment: "Title for alert when trying to save/exit a post before media upload process is complete.")
    static let message = NSLocalizedString("You are currently uploading media. Please wait until this completes.", comment: "This is a notification the user receives if they are trying to save a post (or exit) before the media upload process is complete.")
    static let acceptTitle  = NSLocalizedString("OK", comment: "Accept Action")
}

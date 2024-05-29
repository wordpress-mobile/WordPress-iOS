import Foundation
import WordPressFlux
import WordPressUI

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

    var prepublishingSourceView: UIView? { get }

    var alertBarButtonItem: UIBarButtonItem? { get }

    /// Closure to be executed when the editor gets closed.
    var onClose: ((_ changesSaved: Bool) -> Void)? { get set }

    /// Return the current html in the editor
    func getHTML() -> String

    /// Cancels all ongoing uploads
    func cancelUploadOfAllMedia(for post: AbstractPost)

    /// When the Prepublishing sheet or Prepublishing alert is dismissed, this is called.
    func publishingDismissed()

    func removeFailedMedia()

    /// Returns the word counts of the content in the editor.
    var wordCount: UInt { get }

    /// Debouncer used to save the post locally with a delay
    var debouncer: Debouncer { get }

    /// - warning: deprecated (kahu-offline-mode)
    var prepublishingIdentifiers: [PrepublishingIdentifier] { get }

    func emitPostSaveEvent()
}

var postPublishedReceipt: Receipt?

extension PublishingEditor {

    func publishingDismissed() {
        // Default implementation is empty, can be optionally implemented by other classes.
    }

    func emitPostSaveEvent() {
        // Default implementation is empty, can be optionally implemented by other classes.
    }

    func removeFailedMedia() {
        // TODO: we can only implement this when GB bridge allows removal of blocks
    }

    // The debouncer will perform this callback every 500ms in order to save the post locally with a delay.
    var debouncerCallback: (() -> Void) {
        return { [weak self] in
            guard let self = self else {
                return
            }

            let hasChanges = FeatureFlag.syncPublishing.enabled ? self.post.hasChanges : self.post.hasLocalChanges()
            if hasChanges {
                guard let context = self.post.managedObjectContext else {
                    return
                }
                ContextManager.sharedInstance().save(context)
            }
        }
    }

    func handlePrimaryActionButtonTap() {
        let action = self.postEditorStateContext.action

        guard FeatureFlag.syncPublishing.enabled else {
            publishPost(
                action: action,
                dismissWhenDone: action.dismissesEditor,
                analyticsStat: self.postEditorStateContext.publishActionAnalyticsStat)
            return
        }

        performEditorAction(action, analyticsStat: postEditorStateContext.publishActionAnalyticsStat)
    }

    /// - note: deprecated (kahu-offline-mode)
    func handleSecondaryActionButtonTap() {
        guard let action = self.postEditorStateContext.secondaryPublishButtonAction else {
            // If the user tapped on the secondary publish action button, it means we should have a secondary publish action.
            let error = NSError(domain: EditorError.errorDomain, code: EditorError.expectedSecondaryAction.rawValue, userInfo: nil)
            WordPressAppDelegate.crashLogging?.logError(error)
            return
        }

        let secondaryStat = self.postEditorStateContext.secondaryPublishActionAnalyticsStat

        let publishPostClosure = { [unowned self] in
            publishPost(action: action, dismissWhenDone: action.dismissesEditor, analyticsStat: secondaryStat)
        }

        if presentedViewController != nil {
            dismiss(animated: true, completion: publishPostClosure)
        } else {
            publishPostClosure()
        }
    }

    func performEditorAction(_ action: PostEditorAction, analyticsStat: WPAnalyticsStat?) {
        if action == .publish {
            WPAnalytics.track(.editorPostPublishTap)
        }

        mapUIContentToPostAndSave(immediate: true)

        switch action {
        case .schedule, .publish:
            showPublishingConfirmation(for: action, analyticsStat: analyticsStat)
        case .update:
            guard !isUploadingMedia else {
                return displayMediaIsUploadingAlert()
            }
            performUpdateAction()
        case .submitForReview:
            guard !isUploadingMedia else {
                return displayMediaIsUploadingAlert()
            }
            var changes = RemotePostUpdateParameters()
            changes.status = Post.Status.pending.rawValue
            performUpdateAction(changes: changes)
        case .save, .saveAsDraft:
            wpAssertionFailure("No longer used and supported")
            break
        }
    }

    private func showPublishingConfirmation(for action: PostEditorAction, analyticsStat: WPAnalyticsStat?) {
        displayPublishConfirmationAlert(for: action) { [weak self] result in
            guard let self else { return }
            switch result {
            case .confirmed:
                wpAssertionFailure("Not used when .syncPublishing is enabled")
                break
            case .published:
                self.emitPostSaveEvent()
                if let analyticsStat {
                    self.trackPostSave(stat: analyticsStat)
                }
                self.editorSession.end(outcome: action.analyticsEndOutcome)

                let presentBloggingReminders = JetpackNotificationMigrationService.shared.shouldPresentNotifications()
                self.dismissOrPopView(presentBloggingReminders: presentBloggingReminders)
            case .cancelled:
                self.publishingDismissed()
                WPAnalytics.track(.editorPostPublishDismissed)
            }
        }
    }

    private func performSaveDraftAction() {
        PostCoordinator.shared.setNeedsSync(for: post)
        dismissOrPopView()
    }

    private func performUpdateAction(changes: RemotePostUpdateParameters? = nil) {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()
        postEditorStateContext.updated(isBeingPublished: true)

        Task { @MainActor in
            do {
                let post = try await PostCoordinator.shared._save(post, changes: changes)
                self.post = post
                self.createRevisionOfPost()
            } catch {
                postEditorStateContext.updated(isBeingPublished: false)
            }
            await SVProgressHUD.dismiss()
        }
    }

    /// - note: Deprecated (kahu-offline-mode)
    func publishPost(
        action: PostEditorAction,
        dismissWhenDone: Bool,
        analyticsStat: WPAnalyticsStat?
    ) {
        mapUIContentToPostAndSave(immediate: true)

        // Cancel publishing if media is currently being uploaded
        if !action.isAsync && !dismissWhenDone && isUploadingMedia {
            displayMediaIsUploadingAlert()
            return
        }

        // If the user is trying to publish to WP.com and they haven't verified their account, prompt them to do so.
        if let verificationHelper = verificationPromptHelper, verificationHelper.needsVerification(before: postEditorStateContext.action) {
            verificationHelper.displayVerificationPrompt(from: self) { [unowned self] verifiedInBackground in
                // User could've been plausibly silently verified in the background.
                // If so, proceed to publishing the post as normal, otherwise save it as a draft.
                if !verifiedInBackground {
                    self.post.status = .draft
                }

                self.publishPost(action: action, dismissWhenDone: dismissWhenDone, analyticsStat: analyticsStat)
            }
            return
        }

        let publishBlock = { [unowned self] in
            if action == .saveAsDraft {
                self.post.status = .draft
            } else if action == .publish {
                if self.post.date_created_gmt == nil {
                    self.post.date_created_gmt = Date()
                }

                if self.post.status != .publishPrivate {
                    self.post.status = .publish
                }
            } else if action == .submitForReview {
                self.post.status = .pending
            }

            self.post.isFirstTimePublish = action == .publish

            // self.post.shouldAttemptAutoUpload = true

            emitPostSaveEvent()

            if let analyticsStat = analyticsStat {
                if self is StoryEditor {
                    postPublishedReceipt = ActionDispatcher.global.subscribe({ [self] action in
                        if let noticeAction = action as? NoticeAction {
                            switch noticeAction {
                            case .post:
                                self.trackPostSave(stat: analyticsStat)
                            default:
                                break
                            }
                            postPublishedReceipt = nil
                        }
                    })
                } else {
                    self.trackPostSave(stat: analyticsStat)
                }
            }

            if self.post.isFirstTimePublish {
                QuickStartTourGuide.shared.complete(tour: QuickStartPublishTour(),
                                                    silentlyForBlog: self.post.blog)
            }

            if dismissWhenDone {
                self.editorSession.end(outcome: action.analyticsEndOutcome)
            } else {
                self.editorSession.forceOutcome(action.analyticsEndOutcome)
            }

            if action.isAsync || dismissWhenDone {
                self.asyncUploadPost(action: action)
            } else {
                self.uploadPost(action: action, dismissWhenDone: dismissWhenDone)
            }

            // Track as significant event for App Rating calculations
            AppRatingUtility.shared.incrementSignificantEvent()
        }

        if action.isAsync,
           action != .submitForReview,
           let postStatus = self.post.original?.status ?? self.post.status,
           ![.publish, .publishPrivate].contains(postStatus) {
            WPAnalytics.track(.editorPostPublishTap)

            // Only display confirmation alert for unpublished posts
            displayPublishConfirmationAlert(for: action) { [weak self] result in
                guard let self else { return }
                switch result {
                case .confirmed:
                    publishBlock()
                case .published:
                    self.emitPostSaveEvent()
                    if let analyticsStat {
                        self.trackPostSave(stat: analyticsStat)
                    }
                    self.editorSession.end(outcome: action.analyticsEndOutcome)

                    let presentBloggingReminders = JetpackNotificationMigrationService.shared.shouldPresentNotifications()
                    self.dismissOrPopView(presentBloggingReminders: presentBloggingReminders)
                case .cancelled:
                    self.publishingDismissed()
                    WPAnalytics.track(.editorPostPublishDismissed)
                }
            }
        } else {
            publishBlock()
        }
    }

    func displayPostIsUploadingAlert() {
        let alertController = UIAlertController(title: PostUploadingAlert.title, message: PostUploadingAlert.message, preferredStyle: .alert)
        alertController.addDefaultActionWithTitle(PostUploadingAlert.acceptTitle)
        present(alertController, animated: true, completion: nil)
    }

    func displayMediaIsUploadingAlert() {
        let alertController = UIAlertController(title: MediaUploadingAlert.title, message: MediaUploadingAlert.message, preferredStyle: .alert)
        alertController.addDefaultActionWithTitle(MediaUploadingAlert.acceptTitle)
        present(alertController, animated: true, completion: nil)
    }

    fileprivate func displayPublishConfirmationAlert(for action: PostEditorAction, completion: @escaping (PrepublishingSheetResult) -> Void) {
        PrepublishingViewController.show(for: post, action: action, from: self, completion: completion)
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

        guard FeatureFlag.syncPublishing.enabled else {
            return _cancelEditing()
        }

        guard !post.changes.isEmpty else {
            return discardAndDismiss()
        }

        if post.original().isStatus(in: [.draft, .pending]) {
            if FeatureFlag.autoSaveDrafts.enabled {
                performSaveDraftAction()
            } else {
                // The "Discard Changes" behavior is problematic due to the way
                // the editor and `PostCoordinator` often update the content
                // in the background without the user interaction.
                showCloseDraftConfirmationAlert()
            }
        } else {
            showClosePublishedPostConfirmationAlert()
        }
    }

    private func discardAndDismiss() {
        editorSession.end(outcome: .cancel)
        discardUnsavedChangesAndUpdateGUI()
    }

    /// - note: Deprecated (kahu-offline-mode)
    func _cancelEditing() {
        /// If a post is marked to be auto uploaded and can be saved, it means that the changes
        /// had been already confirmed by the user. In this case, we just close the editor.
        /// Otherwise, we'll show an Action Sheet with options.
        if /* post.shouldAttemptAutoUpload && */ post.canSave() {
            editorSession.end(outcome: .cancel)
            /// If there are ongoing media uploads, save with completion processing
            if MediaCoordinator.shared.isUploadingMedia(for: post) {
                resumeSaving()
            } else {
                dismissOrPopView(didSave: false)
            }
        } else if post.canSave() {
            showPostHasChangesAlert()
        } else {
            editorSession.end(outcome: .cancel)
            discardUnsavedChangesAndUpdateGUI()
        }
    }

    /// - note: Deprecated (kahu-offline-mode)
    private func resumeSaving() {
        // post.shouldAttemptAutoUpload = false
        let action: PostEditorAction = post.status == .draft ? .update : .publish
        self.postEditorStateContext.action = action
        self.publishPost(action: action, dismissWhenDone: true, analyticsStat: nil)
    }

    func discardUnsavedChangesAndUpdateGUI() {
        let postDeleted = discardChanges()
        dismissOrPopView(didSave: !postDeleted)
    }

    @discardableResult
    func discardChanges() -> Bool {
        guard FeatureFlag.syncPublishing.enabled else {
            return _discardChanges()
        }

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

    // Returns true when the post is deleted
    @discardableResult
    func _discardChanges() -> Bool {

        var postDeleted = false
        guard let managedObjectContext = post.managedObjectContext, let originalPost = post.original else {
            return postDeleted
        }

        WPAppAnalytics.track(.editorDiscardedChanges, withProperties: [WPAppAnalyticsKeyEditorSource: analyticsEditorSource], with: post)

        let shouldCreateDummyRevision: Bool

        if post.isLocalRevision {
            // This is basically a reverse of logic in `createRevisionOfPost()` about locally made drafts.
            // Please read that one for context.
            //
            // We're creating an empty revision here to make sure we accurately depict the status of a
            // locally-made-draft-that-was-later-also-locally-revised post.
            //
            // Without this, the app would treat such post just like a regular post — there would be
            // no visible indication in the UI that this is something that only lives locally on users
            // devices — but it wouldn't sync back to your WP blog. That's bad!
            //
            // Doing this silly little dance gives us a neat, useful "Local" indicator displayed next to the
            // post. That's exactly what we want.
            shouldCreateDummyRevision = true
        } else {
            shouldCreateDummyRevision = false
        }

        post = originalPost
        post.remoteStatus = originalPost.remoteStatus
        post.deleteRevision()
        let shouldRemovePostOnDismiss = post.hasNeverAttemptedToUpload() && !post.isLocalRevision

        if shouldRemovePostOnDismiss {
            post.remove()
            postDeleted = true
        } else if shouldCreateDummyRevision {
            post.createRevision()
        }

        cancelUploadOfAllMedia(for: post)
        ContextManager.sharedInstance().saveContextAndWait(managedObjectContext)
        return postDeleted
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

    /// - note: Deprecated (kahu-offline-mode)
    func showPostHasChangesAlert() {
        let title = NSLocalizedString("You have unsaved changes.", comment: "Title of message with options that shown when there are unsaved changes and the author is trying to move away from the post.")
        let cancelTitle = NSLocalizedString("Keep Editing", comment: "Button shown if there are unsaved changes and the author is trying to move away from the post.")
        let saveTitle = NSLocalizedString("Save Draft", comment: "Button shown if there are unsaved changes and the author is trying to move away from the post.")
        let updateTitle = NSLocalizedString("Update Draft", comment: "Button shown if there are unsaved changes and the author is trying to move away from an already saved draft.")
        let updatePostTitle = NSLocalizedString("Update Post", comment: "Button shown if there are unsaved changes and the author is trying to move away from an already published post.")
        let updatePageTitle = NSLocalizedString("Update Page", comment: "Button shown if there are unsaved changes and the author is trying to move away from an already published page.")
        let discardTitle = NSLocalizedString("Discard", comment: "Button shown if there are unsaved changes and the author is trying to move away from the post.")

        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        alertController.view.accessibilityIdentifier = "post-has-changes-alert"

        // Button: Keep editing
        alertController.addCancelActionWithTitle(cancelTitle)

        // Button: Save Draft/Update Draft
        if post.hasLocalChanges() {
            let title: String = {
                if post.status == .draft {
                    if !post.hasRemote() {
                        return saveTitle
                    } else {
                        return updateTitle
                    }
                } else if post is Page {
                    return updatePageTitle
                } else {
                    return updatePostTitle
                }
            }()

            // The post is a local or remote draft
            alertController.addDefaultActionWithTitle(title) { _ in
                let action = self.editorAction()
                self.postEditorStateContext.action = action
                self.publishPost(action: action, dismissWhenDone: true, analyticsStat: self.postEditorStateContext.publishActionAnalyticsStat)
            }
        }

        // Button: Discard
        alertController.addDestructiveActionWithTitle(discardTitle) { _ in
            self.editorSession.end(outcome: .discard)
            self.discardUnsavedChangesAndUpdateGUI()
        }

        alertController.popoverPresentationController?.barButtonItem = alertBarButtonItem
        present(alertController, animated: true, completion: nil)
    }

    private func editorAction() -> PostEditorAction {
        guard post.status != .pending && post.status != .scheduled else {
            return .save
        }

        if post.isLocalDraft {
            return .save
        }

        return post.status == .draft ? .update : .publish
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

    /// Shows the publishing overlay and starts the publishing process.
    ///
    fileprivate func uploadPost(action: PostEditorAction, dismissWhenDone: Bool) {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show(withStatus: action.publishingActionLabel)
        postEditorStateContext.updated(isBeingPublished: true)

        mapUIContentToPostAndSave(immediate: true)

        consolidateChangesIfPostIsNew()

        PostCoordinator.shared.save(post, defaultFailureNotice: uploadFailureNotice(action: action)) { [weak self] result in
            guard let self = self else {
                return
            }
            self.postEditorStateContext.updated(isBeingPublished: false)
            SVProgressHUD.dismiss()

            let generator = UINotificationFeedbackGenerator()
            generator.prepare()

            switch result {
            case .success(let uploadedPost):
                self.post = uploadedPost

                generator.notificationOccurred(.success)
            case .failure(let error):
                DDLogError("Error publishing post: \(error.localizedDescription)")
                generator.notificationOccurred(.error)
            }

            if dismissWhenDone {
                self.dismissOrPopView()
            } else {
                self.createRevisionOfPost()
            }
        }
    }

    /// Starts the publishing process.
    ///
    fileprivate func asyncUploadPost(action: PostEditorAction) {
        postEditorStateContext.updated(isBeingPublished: true)

        mapUIContentToPostAndSave(immediate: true)

        post.updatePathForDisplayImageBasedOnContent()

        PostCoordinator.shared.save(post)

        let presentBloggingReminders = JetpackNotificationMigrationService.shared.shouldPresentNotifications()
        dismissOrPopView(presentBloggingReminders: presentBloggingReminders)

        self.postEditorStateContext.updated(isBeingPublished: false)
    }

    /// If the post is fresh new and doesn't has remote we apply the current changes to the original post
    ///
    /// - note: Deprecated (kahu-offline-mode) – no longer needed before publishing
    fileprivate func consolidateChangesIfPostIsNew() {
        guard post.isRevision() && !post.hasRemote(), let originalPost = post.original else {
            return
        }

        originalPost.applyRevision()
        originalPost.deleteRevision()
        post = originalPost
    }

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
        guard FeatureFlag.syncPublishing.enabled else {
            return _createRevisionOfPost(loadAutosaveRevision: loadAutosaveRevision)
        }
        guard let managedObjectContext = post.managedObjectContext else {
            return wpAssertionFailure("managedObjectContext is missing")
        }

        wpAssert(post.latest() == post, "Must be opened with the latest verison of the post")

        if !post.isUnsavedRevision && post.status != .trash {
            DDLogDebug("Creating new revision")
            post = post._createRevision()
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

    // TODO: Rip this out and put it into the PostService
    // - note: Deprecated (kahu-offline-mode)
    func _createRevisionOfPost(loadAutosaveRevision: Bool = false) {

        if post.isLocalRevision, post.original?.postTitle == nil, post.original?.content == nil {
            // Editing a locally made revision has bit of weirdness in how autosave and
            // revisions interact.
            //
            // Autosave basically is calling `managedObjectContext.save()` every time
            // some time interval ticks (500ms as of me writing this) — but because we're usually in the middle of editing then,
            // the object getting modified is _a revision_ — not the underlying, "base", post itself — that one remains empty/blank.
            //
            // This has some interesting implications when a user comes back to edit that draft later —
            // because the post they're ostensibly editing was just a revision, any subsequent edits made in a later
            // editing sessions also only apply to a revision.
            //
            // If a user then decides that they are unhappy with the changes they made and want to discard them,
            // tapping on "discard changes" then just tosses away the revision and everything should be good.
            //
            // Alas! As I mentioned before, the underlying post _never got saved_ because of the autosave!
            // This means we're removing the "revision" that had all the contents in it and are left with a "shell"
            // of a post with no content in it. Not good!
            //
            // This little dance below, while _very_ counterintuitive, gives us the behavior we want —
            // now when a `revision` is discarded after a second/third/etc/ editing session, there always
            // exists an underlying post with the content users would expect.
            post.original?.applyRevision()
            return
        }

        guard let managedObjectContext = post.managedObjectContext else {
            return
        }

        // Using performBlock: with the AbstractPost on the main context:
        // Prevents a hang on opening this view on slow and fast devices
        // by deferring the cloning and UI update.
        // Slower devices have the effect of the content appearing after
        // a short delay

        managedObjectContext.performAndWait {
            post = self.post.createRevision()

            if loadAutosaveRevision {
                post.postTitle = post.autosaveTitle
                post.mt_excerpt = post.autosaveExcerpt
                post.content = post.autosaveContent
            }

            ContextManager.sharedInstance().save(managedObjectContext)
        }
    }

    var uploadFailureNoticeTag: Notice.Tag {
        return "PostEditor.UploadFailed"
    }

    func uploadFailureNotice(action: PostEditorAction) -> Notice {
        return Notice(title: action.publishingErrorLabel, tag: uploadFailureNoticeTag)
    }
}

private enum EditorError: Int {
    case expectedSecondaryAction = 1

    static let errorDomain = "PostEditor.errorDomain"
}

struct PostEditorDebouncerConstants {
    static let autoSavingDelay =  FeatureFlag.syncPublishing.enabled ? Double(7.0) : Double(0.5)
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

private struct PostUploadingAlert {
    static let title = NSLocalizedString("Uploading post", comment: "Title for alert when trying to preview a post before the uploading process is complete.")
    static let message = NSLocalizedString("Your post is currently being uploaded. Please wait until this completes.", comment: "This is a notification the user receives if they are trying to preview a post before the upload process is complete.")
    static let acceptTitle  = NSLocalizedString("OK", comment: "Accept Action")
}

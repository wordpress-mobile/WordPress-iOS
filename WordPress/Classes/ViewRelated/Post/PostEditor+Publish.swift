import Foundation
import WordPressFlux

protocol PublishingEditor where Self: UIViewController {
    //TODO: Add publishing things
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
    var onClose: ((_ changesSaved: Bool, _ shouldShowPostPost: Bool) -> Void)? { get set }

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

    var prepublishingIdentifiers: [PrepublishingIdentifier] { get }
}

var postPublishedReceipt: Receipt?

extension PublishingEditor {

    func publishingDismissed() {

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

            if self.post.hasLocalChanges() {
                guard let context = self.post.managedObjectContext else {
                    return
                }
                ContextManager.sharedInstance().save(context)
            }
        }
    }

    func handlePublishButtonTap() {
        let action = self.postEditorStateContext.action

        publishPost(
            action: action,
            dismissWhenDone: action.dismissesEditor,
            analyticsStat: self.postEditorStateContext.publishActionAnalyticsStat)
    }



    func publishPost(
        action: PostEditorAction,
        dismissWhenDone: Bool,
        analyticsStat: WPAnalyticsStat?) {

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
            } else if action == .publishNow {
                self.post.date_created_gmt = Date()

                if self.post.status != .publishPrivate {
                    self.post.status = .publish
                }
            } else if action == .submitForReview {
                self.post.status = .pending
            }

            self.post.isFirstTimePublish = action == .publish || action == .publishNow

            self.post.shouldAttemptAutoUpload = true

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
        }

        if action.isAsync,
           let postStatus = self.post.original?.status ?? self.post.status,
           ![.publish, .publishPrivate].contains(postStatus) {
            WPAnalytics.track(.editorPostPublishTap)

            // Only display confirmation alert for unpublished posts
            displayPublishConfirmationAlert(for: action, onPublish: publishBlock, onDismiss: { [weak self] in
                self?.publishingDismissed()
                WPAnalytics.track(.editorPostPublishDismissed)
            })
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

    fileprivate func displayHasFailedMediaAlert(then: @escaping () -> ()) {
        let alertController = UIAlertController(title: FailedMediaRemovalAlert.title, message: FailedMediaRemovalAlert.message, preferredStyle: .alert)
        alertController.addDefaultActionWithTitle(FailedMediaRemovalAlert.acceptTitle) { [weak self] alertAction in
            self?.removeFailedMedia()
            then()
        }

        alertController.addCancelActionWithTitle(FailedMediaRemovalAlert.cancelTitle)
        present(alertController, animated: true, completion: nil)
    }

    /// If the user is publishing a post, displays the Prepublishing Nudges
    /// Otherwise, shows a confirmation Action Sheet.
    ///
    /// - Parameters:
    ///     - action: Publishing action being performed
    ///
    fileprivate func displayPublishConfirmationAlert(for action: PostEditorAction, onPublish publishAction: @escaping () -> (), onDismiss dismissAction: @escaping () -> ()) {
        if let post = post as? Post {
            displayPrepublishingNudges(post: post, onPublish: publishAction, onDismiss: dismissAction)
        } else {
            displayPublishConfirmationAlertForPage(for: action, onPublish: publishAction, onDismiss: dismissAction)
        }
    }

    /// Displays the Prepublishing Nudges Bottom Sheet
    ///
    /// - Parameters:
    ///     - action: Publishing action being performed
    ///
    fileprivate func displayPrepublishingNudges(post: Post, onPublish publishAction: @escaping () -> (), onDismiss dismissAction: @escaping () -> ()) {
        // End editing to avoid issues with accessibility
        view.endEditing(true)

        let prepublishing = PrepublishingViewController(post: post, identifiers: prepublishingIdentifiers) { [weak self] result in
            switch result {
            case .completed(let post):
                self?.post = post
                publishAction()
            case .dismissed:
                dismissAction()
            }
        }

        let prepublishingNavigationController = PrepublishingNavigationController(rootViewController: prepublishing)
        let bottomSheet = BottomSheetViewController(childViewController: prepublishingNavigationController, customHeaderSpacing: 0)
        if let sourceView = prepublishingSourceView {
            bottomSheet.show(from: self, sourceView: sourceView)
        } else {
            bottomSheet.show(from: self.topmostPresentedViewController)
        }
    }

    /// Displays a publish confirmation alert with two options: "Keep Editing" and String for Action.
    ///
    /// - Parameters:
    ///     - action: Publishing action being performed
    ///
    fileprivate func displayPublishConfirmationAlertForPage(for action: PostEditorAction, onPublish publishAction: @escaping () -> (), onDismiss dismissAction: @escaping () -> ()) {
        let title = action.publishingActionQuestionLabel
        let keepEditingTitle = NSLocalizedString("Keep Editing", comment: "Button shown when the author is asked for publishing confirmation.")
        let publishTitle = action.publishActionLabel
        let style: UIAlertController.Style = UIDevice.isPad() ? .alert : .actionSheet
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: style)

        alertController.addCancelActionWithTitle(keepEditingTitle) { _ in
            dismissAction()
        }
        alertController.addDefaultActionWithTitle(publishTitle) { _ in
            publishAction()
        }
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
        }

        WPAppAnalytics.track(stat, withProperties: properties, with: post)
    }

    // MARK: - Close button handling

    func cancelEditing() {
        ActionDispatcher.dispatch(NoticeAction.clearWithTag(uploadFailureNoticeTag))
        stopEditing()

        /// If a post is marked to be auto uploaded and can be saved, it means that the changes
        /// had been already confirmed by the user. In this case, we just close the editor.
        /// Otherwise, we'll show an Action Sheet with options.
        if post.shouldAttemptAutoUpload && post.canSave() {
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

    private func resumeSaving() {
        post.shouldAttemptAutoUpload = false
        let action: PostEditorAction = post.status == .draft ? .update : .publish
        self.postEditorStateContext.action = action
        self.publishPost(action: action, dismissWhenDone: true, analyticsStat: nil)
    }

    func discardUnsavedChangesAndUpdateGUI() {
        let postDeleted = discardChanges()
        dismissOrPopView(didSave: !postDeleted)
    }

    // Returns true when the post is deleted
    @discardableResult
    func discardChanges() -> Bool {
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

        PostCoordinator.shared.save(post,
                                    defaultFailureNotice: uploadFailureNotice(action: action)) { [weak self] result in
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

        dismissOrPopView(presentBloggingReminders: true)

        self.postEditorStateContext.updated(isBeingPublished: false)
    }

    /// If the post is fresh new and doesn't has remote we apply the current changes to the original post
    ///
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
            onClose(didSave, false)
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

    // TODO: Rip this out and put it into the PostService
    func createRevisionOfPost(loadAutosaveRevision: Bool = false) {

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

struct PostEditorDebouncerConstants {
    static let autoSavingDelay = Double(0.5)
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

private struct FailedMediaRemovalAlert {
    static let title = NSLocalizedString("Uploads failed", comment: "Title for alert when trying to save post with failed media items")
    static let message = NSLocalizedString("Some media uploads failed. This action will remove all failed media from the post.\nSave anyway?", comment: "Confirms with the user if they save the post all media that failed to upload will be removed from it.")
    static let acceptTitle  = NSLocalizedString("Yes", comment: "Accept Action")
    static let cancelTitle  = NSLocalizedString("Not Now", comment: "Nicer dialog answer for \"No\".")
}

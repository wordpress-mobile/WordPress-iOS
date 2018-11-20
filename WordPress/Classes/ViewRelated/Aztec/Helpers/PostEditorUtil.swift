import Foundation

typealias PostEditorViewControllerType = UIViewController & PublishablePostEditor

class PostEditorUtil: NSObject {

    fileprivate unowned let context: PostEditorViewControllerType

    fileprivate var post: AbstractPost {
        return context.post
    }

    var postEditorStateContext: PostEditorStateContext {
        return context.postEditorStateContext
    }

    /// For autosaving - The debouncer will execute local saving every defined number of seconds.
    /// In this case every 0.5 second
    ///
    fileprivate var debouncer = Debouncer(delay: Constants.autoSavingDelay)

    init(context: PostEditorViewControllerType) {
        self.context = context

        super.init()

        // The debouncer will perform this callback every 500ms in order to save the post locally with a delay.
        debouncer.callback = { [weak self] in
            guard let strongSelf = self else {
                assertionFailure("self was nil while trying to save a post using Debouncer")
                return
            }
            if strongSelf.post.hasLocalChanges() {
                guard let context = strongSelf.post.managedObjectContext else {
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

        // Cancel publishing if media is currently being uploaded
        if !action.isAsync && !dismissWhenDone && context.isUploadingMedia {
            displayMediaIsUploadingAlert()
            return
        }

        // If there is any failed media allow it to be removed or cancel publishing
        if context.hasFailedMedia {
            displayHasFailedMediaAlert(then: {
                // Failed media is removed, try again.
                // Note: Intentionally not tracking another analytics stat here (no appropriate one exists yet)
                self.publishPost(action: action, dismissWhenDone: dismissWhenDone, analyticsStat: analyticsStat)
            })
            return
        }

        // If the user is trying to publish to WP.com and they haven't verified their account, prompt them to do so.
        if let verificationHelper = context.verificationPromptHelper, verificationHelper.needsVerification(before: postEditorStateContext.action) {
            verificationHelper.displayVerificationPrompt(from: context) { [unowned self] verifiedInBackground in
                // User could've been plausibly silently verified in the background.
                // If so, proceed to publishing the post as normal, otherwise save it as a draft.
                if !verifiedInBackground {
                    self.post.status = .draft
                }

                self.publishPost(action: action, dismissWhenDone: dismissWhenDone, analyticsStat: analyticsStat)
            }
            return
        }

        let isPage = post is Page

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
            }

            if let analyticsStat = analyticsStat {
                self.trackPostSave(stat: analyticsStat)
            }

            if action.isAsync || dismissWhenDone {
                self.asyncUploadPost(action: action)
            } else {
                self.uploadPost(action: action, dismissWhenDone: dismissWhenDone)
            }
        }

        let promoBlock = { [unowned self] in
            UserDefaults.standard.asyncPromoWasDisplayed = true

            let controller = FancyAlertViewController.makeAsyncPostingAlertController(action: action, isPage: isPage, onConfirm: publishBlock)
            controller.modalPresentationStyle = .custom
            controller.transitioningDelegate = self
            self.context.present(controller, animated: true, completion: nil)
        }

        if action.isAsync {
            if !UserDefaults.standard.asyncPromoWasDisplayed {
                promoBlock()
            } else {
                displayPublishConfirmationAlert(for: action, onPublish: publishBlock)
            }
        } else {
            publishBlock()
        }
    }

    fileprivate func displayMediaIsUploadingAlert() {
        let alertController = UIAlertController(title: MediaUploadingAlert.title, message: MediaUploadingAlert.message, preferredStyle: .alert)
        alertController.addDefaultActionWithTitle(MediaUploadingAlert.acceptTitle)
        context.present(alertController, animated: true, completion: nil)
    }

    fileprivate func displayHasFailedMediaAlert(then: @escaping () -> ()) {
        let alertController = UIAlertController(title: FailedMediaRemovalAlert.title, message: FailedMediaRemovalAlert.message, preferredStyle: .alert)
        alertController.addDefaultActionWithTitle(FailedMediaRemovalAlert.acceptTitle) { [weak self] alertAction in
            self?.context.removeFailedMedia()
            then()
        }

        alertController.addCancelActionWithTitle(FailedMediaRemovalAlert.cancelTitle)
        context.present(alertController, animated: true, completion: nil)
    }

    /// Displays a publish confirmation alert with two options: "Keep Editing" and String for Action.
    ///
    /// - Parameters:
    ///     - action: Publishing action being performed
    ///     - dismissWhenDone: if `true`, the VC will be dismissed if the user picks "Publish".
    ///
    fileprivate func displayPublishConfirmationAlert(for action: PostEditorAction, onPublish publishAction: @escaping () -> ()) {
        let title = action.publishingActionQuestionLabel
        let keepEditingTitle = NSLocalizedString("Keep Editing", comment: "Button shown when the author is asked for publishing confirmation.")
        let publishTitle = action.publishActionLabel
        let style: UIAlertController.Style = UIDevice.isPad() ? .alert : .actionSheet
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: style)

        alertController.addCancelActionWithTitle(keepEditingTitle)
        alertController.addDefaultActionWithTitle(publishTitle) { _ in
            publishAction()
        }
        context.present(alertController, animated: true, completion: nil)
    }

    private func trackPostSave(stat: WPAnalyticsStat) {
        guard stat != .editorSavedDraft && stat != .editorQuickSavedDraft else {
            WPAppAnalytics.track(stat, withProperties: [WPAppAnalyticsKeyEditorSource: context.analyticsEditorSource], with: post.blog)
            return
        }

        let originalWordCount = post.original?.content?.wordCount() ?? 0
        let wordCount = post.content?.wordCount() ?? 0
        var properties: [String: Any] = ["word_count": wordCount, WPAppAnalyticsKeyEditorSource: context.analyticsEditorSource]
        if post.hasRemote() {
            properties["word_diff_count"] = originalWordCount
        }

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
        stopEditing()

        if post.canSave() && post.hasUnsavedChanges() {
            showPostHasChangesAlert()
        } else {
            discardChangesAndUpdateGUI()
        }
    }

    func discardChangesAndUpdateGUI() {
        discardChanges()

        dismissOrPopView(didSave: false)
    }

    func discardChanges() {
        guard let managedObjectContext = post.managedObjectContext, let originalPost = post.original else {
            return
        }

        WPAppAnalytics.track(.editorDiscardedChanges, withProperties: [WPAppAnalyticsKeyEditorSource: context.analyticsEditorSource], with: post)

        context.post = originalPost
        context.post.deleteRevision()

        if context.shouldRemovePostOnDismiss {
            post.remove()
        }

        context.cancelUploadOfAllMedia(for: post)
        ContextManager.sharedInstance().save(managedObjectContext)
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
                let action: PostEditorAction = (self.post.status == .draft) ? .saveAsDraft : .publish
                self.publishPost(action: action, dismissWhenDone: true, analyticsStat: self.postEditorStateContext.publishActionAnalyticsStat)
            }
        }

        // Button: Discard
        alertController.addDestructiveActionWithTitle(discardTitle) { _ in
            self.discardChangesAndUpdateGUI()
        }

        alertController.popoverPresentationController?.barButtonItem = context.navigationBarManager.closeBarButtonItem
        context.present(alertController, animated: true, completion: nil)
    }

}

extension PostEditorUtil: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        guard presented is FancyAlertViewController else {
            return nil
        }

        return FancyAlertPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

// MARK: - Publishing

extension PostEditorUtil {

    /// Shows the publishing overlay and starts the publishing process.
    ///
    fileprivate func uploadPost(action: PostEditorAction, dismissWhenDone: Bool) {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show(withStatus: action.publishingActionLabel)
        postEditorStateContext.updated(isBeingPublished: true)

        uploadPost() { [weak self] uploadedPost, error in
            guard let strongSelf = self else {
                return
            }
            strongSelf.postEditorStateContext.updated(isBeingPublished: false)
            SVProgressHUD.dismiss()

            let generator = UINotificationFeedbackGenerator()
            generator.prepare()

            if let error = error {
                DDLogError("Error publishing post: \(error.localizedDescription)")

                SVProgressHUD.showDismissibleError(withStatus: action.publishingErrorLabel)
                generator.notificationOccurred(.error)
            } else if let uploadedPost = uploadedPost {
                strongSelf.context.post = uploadedPost

                generator.notificationOccurred(.success)
            }

            if dismissWhenDone {
                strongSelf.dismissOrPopView(didSave: true)
            } else {
                strongSelf.createRevisionOfPost()
            }
        }
    }

    /// Starts the publishing process.
    ///
    fileprivate func asyncUploadPost(action: PostEditorAction) {
        postEditorStateContext.updated(isBeingPublished: true)

        mapUIContentToPostAndSave()

        post.updatePathForDisplayImageBasedOnContent()

        PostCoordinator.shared.save(post: post)

        dismissOrPopView(didSave: true, shouldShowPostEpilogue: false)

        self.postEditorStateContext.updated(isBeingPublished: false)
    }

    /// Uploads the post
    ///
    /// - Parameters:
    ///     - completion: the closure to execute when the publish operation completes.
    ///
    private func uploadPost(completion: ((_ post: AbstractPost?, _ error: Error?) -> Void)?) {
        mapUIContentToPostAndSave()

        let managedObjectContext = ContextManager.sharedInstance().mainContext
        let postService = PostService(managedObjectContext: managedObjectContext)
        postService.uploadPost(post, success: { uploadedPost in
            completion?(uploadedPost, nil)
        }) { error in
            completion?(nil, error)
        }
    }

    func dismissOrPopView(didSave: Bool, shouldShowPostEpilogue: Bool = true) {
        stopEditing()

        WPAppAnalytics.track(.editorClosed, withProperties: [WPAppAnalyticsKeyEditorSource: context.analyticsEditorSource], with: post)

        if let onClose = context.onClose {
            onClose(didSave, shouldShowPostEpilogue)
        } else if context.isModal() {
            context.presentingViewController?.dismiss(animated: true, completion: nil)
        } else {
            _ = context.navigationController?.popViewController(animated: true)
        }
    }

    func stopEditing() {
        context.view.endEditing(true)
    }

    func mapUIContentToPostAndSave() {
        post.postTitle = context.postTitle
        post.content = context.getHTML()
        debouncer.call()
    }

    // TODO: Rip this out and put it into the PostService
    func createRevisionOfPost() {
        guard let managedObjectContext = post.managedObjectContext else {
            return
        }

        // Using performBlock: with the AbstractPost on the main context:
        // Prevents a hang on opening this view on slow and fast devices
        // by deferring the cloning and UI update.
        // Slower devices have the effect of the content appearing after
        // a short delay

        managedObjectContext.performAndWait {
            context.post = self.post.createRevision()
            ContextManager.sharedInstance().save(managedObjectContext)
        }
    }
}

extension PostEditorUtil {

    struct Constants {
        static let autoSavingDelay = Double(0.5)
    }

    struct Analytics {
        static let headerStyleValues = ["none", "h1", "h2", "h3", "h4", "h5", "h6"]
    }

    struct MediaUploadingAlert {
        static let title = NSLocalizedString("Uploading media", comment: "Title for alert when trying to save/exit a post before media upload process is complete.")
        static let message = NSLocalizedString("You are currently uploading media. Please wait until this completes.", comment: "This is a notification the user receives if they are trying to save a post (or exit) before the media upload process is complete.")
        static let acceptTitle  = NSLocalizedString("OK", comment: "Accept Action")
    }

    struct FailedMediaRemovalAlert {
        static let title = NSLocalizedString("Uploads failed", comment: "Title for alert when trying to save post with failed media items")
        static let message = NSLocalizedString("Some media uploads failed. This action will remove all failed media from the post.\nSave anyway?", comment: "Confirms with the user if they save the post all media that failed to upload will be removed from it.")
        static let acceptTitle  = NSLocalizedString("Yes", comment: "Accept Action")
        static let cancelTitle  = NSLocalizedString("Not Now", comment: "Nicer dialog answer for \"No\".")
    }
}

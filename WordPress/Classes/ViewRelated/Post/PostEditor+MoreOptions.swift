import Foundation
import WordPressFlux

extension PostEditor {

    func displayPostSettings() {
        let settingsViewController: PostSettingsViewController
        if post is Page {
            settingsViewController = PageSettingsViewController(post: post)
        } else {
            settingsViewController = PostSettingsViewController(post: post)
        }
        settingsViewController.featuredImageDelegate = self as? FeaturedImageDelegate
        let doneButton = UIBarButtonItem(systemItem: .done, primaryAction: .init(handler: { [weak self] _ in
            self?.editorContentWasUpdated()
            self?.navigationController?.dismiss(animated: true)
        }))
        doneButton.accessibilityIdentifier = "close"
        settingsViewController.navigationItem.rightBarButtonItem = doneButton

        let navigation = UINavigationController(rootViewController: settingsViewController)
        self.navigationController?.present(navigation, animated: true)
    }

    private func createPostRevisionBeforePreview(completion: @escaping (() -> Void)) {
        let context = ContextManager.sharedInstance().mainContext
        context.performAndWait {
            post = self.post.createRevision()
            ContextManager.sharedInstance().save(context)
            completion()
        }
    }

    private func savePostBeforePreview(completion: @escaping ((String?, Error?) -> Void)) {
        guard RemoteFeatureFlag.syncPublishing.enabled() else {
            return _savePostBeforePreview(completion: completion)
        }

        guard !post.changes.isEmpty else {
            completion(nil, nil)
            return
        }

        Task { @MainActor in
            let coordinator = PostCoordinator.shared
            do {
                if post.isStatus(in: [.draft, .pending]) {
                    SVProgressHUD.setDefaultMaskType(.clear)
                    SVProgressHUD.show(withStatus: Strings.savingDraft)

                    let original = post.original()
                    try await coordinator._save(original)
                    self.post = original
                    self.createRevisionOfPost()

                    completion(nil, nil)
                } else {
                    SVProgressHUD.setDefaultMaskType(.clear)
                    SVProgressHUD.show(withStatus: Strings.creatingAutosave)
                    let autosave = try await PostRepository().autosave(post)
                    completion(autosave.previewURL.absoluteString, nil)
                }
            } catch {
                completion(nil, error)
            }
        }
    }

    // - warning: deprecated (kahu-offline-mode)
    private func _savePostBeforePreview(completion: @escaping ((String?, Error?) -> Void)) {
        let context = ContextManager.sharedInstance().mainContext
        let postService = PostService(managedObjectContext: context)

        if !post.hasUnsavedChanges() {
            completion(nil, nil)
            return
        }

        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show(withStatus: NSLocalizedString("Generating Preview", comment: "Message to indicate progress of generating preview"))

        postService.autoSave(post, success: { [weak self] savedPost, previewURL in

            guard let self = self else {
                return
            }

            self.post = savedPost

            if self.post.isRevision() {
                ContextManager.sharedInstance().save(context)
                completion(previewURL, nil)
            } else {
                self.createPostRevisionBeforePreview() {
                    completion(previewURL, nil)
                }
            }
        }) { error in

            //When failing to save a published post will result in "preview not available"
            DDLogError("Error while trying to save post before preview: \(String(describing: error))")
            completion(nil, error)
        }
    }

    private func displayPreviewNotAvailable(title: String, subtitle: String? = nil) {
        let noResultsController = NoResultsViewController.controllerWith(title: title, subtitle: subtitle)
        noResultsController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(noResultsController, animated: true)
    }

    func displayPreview() {
        guard !isUploadingMedia else {
            displayMediaIsUploadingAlert()
            return
        }

        if !RemoteFeatureFlag.syncPublishing.enabled() {
            guard post.remoteStatus != .pushing else {
                displayPostIsUploadingAlert()
                return
            }
        }

        emitPostSaveEvent()

        savePostBeforePreview() { [weak self] previewURLString, error in
            guard let self = self else {
                return
            }

            SVProgressHUD.dismiss()

            if error != nil {
                let title = NSLocalizedString("Preview Unavailable", comment: "Title on display preview error" )
                self.displayPreviewNotAvailable(title: title)
                return
            }

            let previewController: PreviewWebKitViewController
            if let previewURLString = previewURLString, let previewURL = URL(string: previewURLString) {
                previewController = PreviewWebKitViewController(post: self.post, previewURL: previewURL, source: "edit_post_more_preview")
            } else {
                if self.post.permaLink == nil {
                    DDLogError("displayPreview: Post permalink is unexpectedly nil")
                    self.displayPreviewNotAvailable(title: NSLocalizedString("Preview Unavailable", comment: "Title on display preview error" ))
                    return
                }
                previewController = PreviewWebKitViewController(post: self.post, source: "edit_post_more_preview")
            }
            previewController.trackOpenEvent()
            let navWrapper = LightNavigationController(rootViewController: previewController)
            if self.navigationController?.traitCollection.userInterfaceIdiom == .pad {
                navWrapper.modalPresentationStyle = .fullScreen
            }
            self.navigationController?.present(navWrapper, animated: true)
        }
    }

    func displayHistory() {
        guard RemoteFeatureFlag.syncPublishing.enabled() else {
            _displayHistory()
            return
        }
        let viewController = RevisionsTableViewController(post: post) { _ in }
        viewController.onRevisionSelected = { [weak self] revision in
            guard let self else { return }

            self.navigationController?.popViewController(animated: true)

            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                self.post.postTitle = revision.postTitle
                self.post.content = revision.postContent
                self.post.mt_excerpt = revision.postExcerpt

                self.post = self.post // Reload the ui

                let notice = Notice(title: Strings.revisionLoaded, feedbackType: .success)
                ActionDispatcher.dispatch(NoticeAction.post(notice))
            }
        }
        navigationController?.pushViewController(viewController, animated: true)
    }

    /// - warning: deprecated (kahu-offline-mode)
    private func _displayHistory() {
        let revisionsViewController = RevisionsTableViewController(post: post) { [weak self] revision in
            guard let post = self?.post.update(from: revision) else {
                return
            }

            // show the notice with undo button
            let notice = Notice(title: "Revision loaded", message: nil, feedbackType: .success, notificationInfo: nil, actionTitle: "Undo", cancelTitle: nil) { (happened) in
                guard happened else {
                    return
                }
                DispatchQueue.main.async {
                    guard let original = self?.post.original(),
                        let clone = self?.post.clone(from: original) else {
                        return
                    }
                    self?.post = clone

                    WPAnalytics.track(.postRevisionsLoadUndone)
                }
            }
            ActionDispatcher.dispatch(NoticeAction.post(notice))

            DispatchQueue.main.async {
                self?.post = post
            }
        }
        navigationController?.pushViewController(revisionsViewController, animated: true)
    }
}

private enum Strings {
    static let savingDraft = NSLocalizedString("postEditor.savingDraftForPreview", value: "Saving draft...", comment: "Saving draft to generate a preview (status message")
    static let creatingAutosave = NSLocalizedString("postEditor.creatingAutosaveForPreview", value: "Creating autosave...", comment: "Creating autosave to generate a preview (status message")
    static let revisionLoaded = NSLocalizedString("postEditor.revisionLoaded", value: "Revision loaded", comment: "Title for a snackbar")
}

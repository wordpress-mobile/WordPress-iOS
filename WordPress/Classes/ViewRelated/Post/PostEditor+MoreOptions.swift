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
        settingsViewController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(settingsViewController, animated: true)
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
        let context = ContextManager.sharedInstance().mainContext
        let postService = PostService(managedObjectContext: context)

        if !post.hasUnsavedChanges() {
            completion(nil, nil)
            return
        }

        navigationBarManager.reloadTitleView(navigationBarManager.generatingPreviewTitleView)

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

        guard post.remoteStatus != .pushing else {
            displayPostIsUploadingAlert()
            return
        }

        savePostBeforePreview() { [weak self] previewURLString, error in
            guard let self = self else {
                return
            }

            let navigationBarManager = self.navigationBarManager
            navigationBarManager.reloadTitleView(navigationBarManager.blogTitleViewLabel)

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
                    guard let original = self?.post.original,
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

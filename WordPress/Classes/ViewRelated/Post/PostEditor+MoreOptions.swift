import Foundation
import WordPressFlux

extension PostEditor where Self: UIViewController {

    func displayPostSettings() {
        let settingsViewController: PostSettingsViewController
        if post is Page {
            settingsViewController = PageSettingsViewController(post: post)
        } else {
            settingsViewController = PostSettingsViewController(post: post)
        }
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

        if post.isDraft() {
            navigationBarManager.reloadLeftBarButtonItems(navigationBarManager.savingDraftLeftBarButtonItems)
            postService.uploadPost(post, success: { [weak self] savedPost in
                self?.post = savedPost
                self?.createPostRevisionBeforePreview() {
                    completion(nil, nil)
                }
                }, failure: { error in
                    DDLogError("Error while trying to upload draft before preview: \(String(describing: error))")
                    completion(nil, nil)
            })
        } else {
            navigationBarManager.reloadLeftBarButtonItems(navigationBarManager.generatingPreviewLeftBarButtonItems)
            postService.autoSave(post, success: { [weak self] savedPost, previewURL in
                self?.post = savedPost
                ContextManager.sharedInstance().save(context)
                completion(previewURL, nil)
            }) { error in
                //When failing to save a published post will result in "preview not available"
                DDLogError("Error while trying to save post before preview: \(String(describing: error))")
                completion(nil, error)
            }
        }
    }

    private func displayPreviewNotAvailable(title: String, subtitle: String? = nil) {
        let noResultsController = NoResultsViewController.controllerWith(title: title, subtitle: subtitle)
        noResultsController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(noResultsController, animated: true)
    }

    func displayPreview() {
        savePostBeforePreview() { [weak self] previewURLString, error in
            if error != nil {
                let title = NSLocalizedString("Preview Unavailable", comment: "Title on display preview error" )
                self?.displayPreviewNotAvailable(title: title)
                return
            }
            guard let post = self?.post else {
                return
            }
            var previewController: PostPreviewViewController
            if let previewURLString = previewURLString, let previewURL = URL(string: previewURLString) {
                previewController = PostPreviewViewController(post: post, previewURL: previewURL)
            } else {
                if post.permaLink == nil {
                    DDLogError("displayPreview: Post permalink is unexpectedly nil")
                    self?.displayPreviewNotAvailable(title: NSLocalizedString("Preview Unavailable", comment: "Title on display preview error" ))
                    return
                }
                previewController = PostPreviewViewController(post: post)
            }
            previewController.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(previewController, animated: true)
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

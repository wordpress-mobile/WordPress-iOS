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

    private func savePostBeforePreview(completion: @escaping (() -> Void)) {
        if post.isDraft() && post.hasUnsavedChanges() {
            let context = ContextManager.sharedInstance().mainContext
            let postService = PostService(managedObjectContext: context)
             let status = NSLocalizedString("Saving...", comment: "Text displayed in HUD while a post is being saved as a draft.")
            SVProgressHUD.setDefaultMaskType(.clear)
            SVProgressHUD.show(withStatus: status)
            postService.uploadPost(post, success: { [weak self] newPost in
                self?.post = newPost
                self?.createPostRevisionBeforePreview(completion: completion)
                SVProgressHUD.dismiss()
                }, failure: { error in
                    DDLogError("Error while trying to save post before preview: \(String(describing: error))")
                    completion()
                    SVProgressHUD.dismiss()
            })
        } else {
           createPostRevisionBeforePreview(completion: completion)
        }
    }

    func displayPreview() {
        savePostBeforePreview() { [weak self] in
            guard let post = self?.post else {
                return
            }
            let previewController = PostPreviewViewController(post: post)
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

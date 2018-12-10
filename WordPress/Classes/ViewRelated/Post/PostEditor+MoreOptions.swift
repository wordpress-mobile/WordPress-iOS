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

    func displayPreview() {
        let previewController = PostPreviewViewController(post: post)
        previewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(previewController, animated: true)
    }

    func displayHistory() {
        let revisionsViewController = RevisionsTableViewController(post: post) { [weak self] revision in
            guard let self = self else {
                return
            }
            let post = self.post.update(from: revision)

            // show the notice with undo button
            let notice = Notice(title: "Revision loaded", message: nil, feedbackType: .success, notificationInfo: nil, actionTitle: "Undo", cancelTitle: nil) { [weak self] (happened) in
                guard happened, let self = self else {
                    return
                }
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, let original = self.post.original else {
                        return
                    }
                    let clone = self.post.clone(from: original)
                    self.post = clone
                }
            }
            ActionDispatcher.dispatch(NoticeAction.post(notice))

            DispatchQueue.main.async {
                self.post = post
            }
        }
        navigationController?.pushViewController(revisionsViewController, animated: true)
    }
}

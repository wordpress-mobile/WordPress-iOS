import Foundation


extension PublishablePostEditor where Self: UIViewController {

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
            if let post = self?.post.update(from: revision) {
                DispatchQueue.main.async {
                    self?.post = post
                }
            }
        }
        navigationController?.pushViewController(revisionsViewController, animated: true)
    }
}

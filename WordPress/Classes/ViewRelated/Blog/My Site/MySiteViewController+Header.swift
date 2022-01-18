import Foundation
import UIKit
import WordPressShared

extension MySiteViewController {

    func configureHeaderView() -> NewBlogDetailHeaderView {
        return NewBlogDetailHeaderView(items: [])
    }

}

extension MySiteViewController: BlogDetailHeaderViewDelegate {

    func siteIconTapped() {
        // TODO
    }

    func siteIconReceivedDroppedImage(_ image: UIImage?) {
        // TODO
    }

    func siteIconShouldAllowDroppedImages() -> Bool {
        // TODO
        return false
    }

    func siteTitleTapped() {
        // TODO
    }

    func siteSwitcherTapped() {
        guard let blogListController = BlogListViewController(meScenePresenter: meScenePresenter) else {
            return
        }

        blogListController.blogSelected = { [weak self] controller, selectedBlog in
            guard let blog = selectedBlog else {
                return
            }
            self?.switchToBlog(blog)
            controller?.dismiss(animated: true)
        }

        let navigationController = UINavigationController(rootViewController: blogListController)
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true)

        WPAnalytics.track(.mySiteSiteSwitcherTapped)
    }

    func visitSiteTapped() {
        // TODO
    }
}

extension MySiteViewController {

    private func switchToBlog(_ blog: Blog) {
        self.blog = blog
        blogDetailHeaderView.blog = blog

        blogDetailsViewController?.showInitialDetailsForBlog()
        blogDetailsViewController?.tableView.reloadData()
        blogDetailsViewController?.preloadMetadata()
    }
}

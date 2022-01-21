import UIKit

class DashboardPostsCardCell: UICollectionViewCell, Reusable {
    func configure(_ viewController: UIViewController, blog: Blog) {
        let postsViewController = PostsCardViewController(blog: blog)
        viewController.addChild(postsViewController)
        contentView.addSubview(postsViewController.view)
        postsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.pinSubviewToAllEdges(postsViewController.view)
        postsViewController.didMove(toParent: viewController)
    }
}

import UIKit

class DashboardPostsCardCell: UICollectionViewCell, Reusable, BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, dataModel: NSDictionary?) {
        guard let viewController = viewController else {
            return
        }

        let postsViewController = PostsCardViewController(blog: blog)
        viewController.addChild(postsViewController)
        contentView.addSubview(postsViewController.view)
        postsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.pinSubviewToAllEdges(postsViewController.view)
        postsViewController.didMove(toParent: viewController)
    }
}

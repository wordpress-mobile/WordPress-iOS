import UIKit

class DashboardPostsCardCell: UICollectionViewCell, Reusable, BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, dataModel: NSDictionary?) {
        guard let viewController = viewController, let dataModel = dataModel else {
            return
        }

        let hasDrafts = dataModel["show_drafts"] as? Bool ?? false
        let hasScheduled = dataModel["show_scheduled"] as? Bool ?? false

        let postsViewController = PostsCardViewController(blog: blog)

        if hasDrafts {
            postsViewController.status = .draft
        } else if hasScheduled {
            postsViewController.status = .scheduled
        }

        viewController.addChild(postsViewController)
        contentView.addSubview(postsViewController.view)
        postsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.pinSubviewToAllEdges(postsViewController.view)
        postsViewController.didMove(toParent: viewController)
    }
}

import UIKit

class DashboardPostsCardCell: UICollectionViewCell, Reusable, BlogDashboardCardConfigurable {
    private var postsViewController: PostsCardViewController?

    func configure(blog: Blog, viewController: BlogDashboardViewController?, dataModel: NSDictionary?) {
        guard let viewController = viewController, let dataModel = dataModel else {
            return
        }

        /// Create the Child VC in case it doesn't exist
        if postsViewController == nil {
            let postsViewController = PostsCardViewController(blog: blog, status: .draft)
            self.postsViewController = postsViewController

            // Update with the correct blog and status
            updatePosts(dataModel, blog: blog)

            embedChildPostsViewController(to: viewController)
        } else {
            updatePosts(dataModel, blog: blog)
        }
    }

    /// Updates the child VC to display draft or scheduled based on the dataModel
    private func updatePosts(_ dataModel: NSDictionary, blog: Blog) {
        let hasDrafts = dataModel["show_drafts"] as? Bool ?? false
        let hasScheduled = dataModel["show_scheduled"] as? Bool ?? false

        if hasDrafts {
            postsViewController?.update(blog: blog, status: .draft)
        } else if hasScheduled {
            postsViewController?.update(blog: blog, status: .scheduled)
        } else {
            // Temporary: it should display "write your next post"
            postsViewController?.update(blog: blog, status: .draft)
        }
    }

    private func embedChildPostsViewController(to viewController: UIViewController) {
        guard let postsViewController = postsViewController else {
            return
        }

        viewController.addChild(postsViewController)
        contentView.addSubview(postsViewController.view)
        postsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.pinSubviewToAllEdges(postsViewController.view)
        postsViewController.didMove(toParent: viewController)
    }
}

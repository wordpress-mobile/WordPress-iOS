import UIKit

class DashboardPostsCardCell: UICollectionViewCell, Reusable, BlogDashboardCardConfigurable {
    private var postsViewController: PostsCardViewController?

    func configure(blog: Blog, viewController: BlogDashboardViewController?, dataModel: NSDictionary?) {
        guard let viewController = viewController, let dataModel = dataModel else {
            return
        }

        /// Create the child VC in case it doesn't exist
        if postsViewController == nil {
            let postsViewController = PostsCardViewController(blog: blog)
            self.postsViewController = postsViewController
            showDraftsOrScheduled(dataModel)

            // Embed in this cell and configure as a child VC
            viewController.addChild(postsViewController)
            contentView.addSubview(postsViewController.view)
            postsViewController.view.translatesAutoresizingMaskIntoConstraints = false
            contentView.pinSubviewToAllEdges(postsViewController.view)
            postsViewController.didMove(toParent: viewController)
        } else {
            showDraftsOrScheduled(dataModel)
        }
    }

    private func showDraftsOrScheduled(_ dataModel: NSDictionary) {
        let hasDrafts = dataModel["show_drafts"] as? Bool ?? false
        let hasScheduled = dataModel["show_scheduled"] as? Bool ?? false

        if hasDrafts {
            postsViewController?.status = .draft
        } else if hasScheduled {
            postsViewController?.status = .scheduled
        }
    }
}

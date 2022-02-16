import UIKit

class DashboardPostsCardCell: UICollectionViewCell, Reusable, BlogDashboardCardConfigurable {
    private var draftPostsViewController: PostsCardViewController?

    private var scheduledPostsViewController: PostsCardViewController?

    private var cardFrameView: BlogDashboardCardFrameView?

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 20
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(stackView)
        contentView.pinSubviewToAllEdges(stackView)
    }


    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        guard let viewController = viewController, let apiResponse = apiResponse else {
            return
        }

        let hasDrafts = (apiResponse.posts?.draft?.count ?? 0) > 0
        let hasScheduled = (apiResponse.posts?.scheduled?.count ?? 0) > 0

        removeAllChildVCs()

        if !hasDrafts && !hasScheduled {
            let hasPublished = apiResponse.posts?.hasPublished ?? true
            let postsViewController = PostsCardViewController(blog: blog, status: .draft, hasPublishedPosts: hasPublished)
            postsViewController.delegate = self
            draftPostsViewController = postsViewController

            embed(child: postsViewController, to: viewController, with: Strings.draftsTitle)
        } else {
            if hasDrafts {
                let postsViewController = PostsCardViewController(blog: blog, status: .draft)
                draftPostsViewController = postsViewController

                embed(child: postsViewController, to: viewController, with: Strings.draftsTitle)
            }

            if hasScheduled {
                let postsViewController = PostsCardViewController(blog: blog, status: .scheduled)
                scheduledPostsViewController = postsViewController

                embed(child: postsViewController, to: viewController, with: Strings.scheduledTitle)
            }
        }
    }

    private func removeAllChildVCs() {
        stackView.removeAllSubviews()

        if let draftPostsViewController = draftPostsViewController {
            remove(child: draftPostsViewController)
        }

        if let schedulePostsViewController = scheduledPostsViewController {
            remove(child: schedulePostsViewController)
        }

        draftPostsViewController = nil
        scheduledPostsViewController = nil
    }

    private func embed(child childViewController: UIViewController, to viewController: UIViewController, with title: String?) {
        let frame = BlogDashboardCardFrameView()

        if let title = title {
            frame.title = title
            frame.icon = UIImage.gridicon(.posts, size: CGSize(width: 18, height: 18))
        } else {
            frame.hideHeader()
        }

        frame.add(subview: childViewController.view)

        viewController.addChild(childViewController)
        stackView.addArrangedSubview(frame)
        childViewController.didMove(toParent: viewController)

        self.cardFrameView = frame
    }

    private func remove(child childViewController: UIViewController) {
        childViewController.willMove(toParent: nil)
        childViewController.view.removeFromSuperview()
        childViewController.removeFromParent()
    }

    private enum Strings {
        static let draftsTitle = NSLocalizedString("Work on a draft post", comment: "Title for the card displaying draft posts.")
        static let scheduledTitle = NSLocalizedString("Upcoming scheduled posts", comment: "Title for the card displaying upcoming scheduled posts.")
    }
}

extension DashboardPostsCardCell: PostsCardViewControllerDelegate {
    func didShowNextPostPrompt() {
        cardFrameView?.hideHeader()
    }

    func didHideNextPostPrompt() {
        cardFrameView?.showHeader()
    }
}

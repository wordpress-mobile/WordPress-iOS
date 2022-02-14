import UIKit

class DashboardPostsCardCell: UICollectionViewCell, Reusable, BlogDashboardCardConfigurable {
    private var draftPostsViewController: PostsCardViewController?

    private var schedulePostsViewController: PostsCardViewController?

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
            // Temporary: it should display "write your next post"
            let postsViewController = PostsCardViewController(blog: blog, status: .draft)
            draftPostsViewController = postsViewController

            embed(child: postsViewController, to: viewController)
        } else {
            if hasDrafts {
                let postsViewController = PostsCardViewController(blog: blog, status: .draft)
                draftPostsViewController = postsViewController

                embed(child: postsViewController, to: viewController)
            }

            if hasScheduled {
                let postsViewController = PostsCardViewController(blog: blog, status: .scheduled)
                schedulePostsViewController = postsViewController

                embed(child: postsViewController, to: viewController)
            }
        }
    }

    private func removeAllChildVCs() {
        stackView.removeAllSubviews()

        if let draftPostsViewController = draftPostsViewController {
            remove(child: draftPostsViewController)
        }

        if let schedulePostsViewController = schedulePostsViewController {
            remove(child: schedulePostsViewController)
        }

        draftPostsViewController = nil
        schedulePostsViewController = nil
    }

    private func embed(child childViewController: UIViewController, to viewController: UIViewController) {
        viewController.addChild(childViewController)
        stackView.addArrangedSubview(childViewController.view)
        childViewController.didMove(toParent: viewController)
    }

    private func remove(child childViewController: UIViewController) {
        childViewController.willMove(toParent: nil)
        childViewController.view.removeFromSuperview()
        childViewController.removeFromParent()
    }
}

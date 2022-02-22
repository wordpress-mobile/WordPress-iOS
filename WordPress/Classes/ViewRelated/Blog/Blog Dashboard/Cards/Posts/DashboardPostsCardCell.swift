import UIKit

class DashboardPostsCardCell: UICollectionViewCell, Reusable, BlogDashboardCardConfigurable {
    private var cardFrameView: BlogDashboardCardFrameView?

    /// The VC presenting this cell
    private weak var viewController: UIViewController?

    private var blog: Blog?

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

        self.viewController = viewController
        self.blog = blog

        let hasDrafts = (apiResponse.posts?.draft?.count ?? 0) > 0
        let hasScheduled = (apiResponse.posts?.scheduled?.count ?? 0) > 0
        let hasPublished = apiResponse.posts?.hasPublished ?? true

        removeAllChildVCs()

        if !hasDrafts && !hasScheduled {
            showCard(forBlog: blog, status: .draft, to: viewController, hasPublishedPosts: hasPublished, hiddenHeader: true, shouldSync: false)
        } else {
            if hasDrafts {
                showCard(forBlog: blog, status: .draft, to: viewController, hasPublishedPosts: hasPublished)
            }

            if hasScheduled {
                showCard(forBlog: blog, status: .scheduled, to: viewController, hasPublishedPosts: hasPublished)
            }
        }
    }

    private func removeAllChildVCs() {
        let childVcs = viewController?.children.filter { $0 is PostsCardViewController }

        stackView.removeAllSubviews()

        childVcs?.forEach { remove(child: $0) }
    }

    private func showCard(forBlog blog: Blog, status: BasePost.Status, to viewController: UIViewController, hasPublishedPosts: Bool, hiddenHeader: Bool = false, shouldSync: Bool = true) {
        // Create the VC to present posts
        let childViewController = PostsCardViewController(blog: blog, status: status, hasPublishedPosts: hasPublishedPosts, shouldSync: shouldSync)
        childViewController.delegate = self

        // Create the card frame and configure
        let frame = BlogDashboardCardFrameView()
        frame.title = status == .draft ? Strings.draftsTitle : Strings.scheduledTitle
        frame.icon = UIImage.gridicon(.posts, size: CGSize(width: 18, height: 18))

        if hiddenHeader {
            frame.hideHeader()
        }

        frame.onHeaderTap = { [weak self] in
            self?.presentPostList(with: status)
        }

        // Add the VC to the card frame and configure as a child VC
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

    private func presentPostList(with status: BasePost.Status) {
        guard let blog = blog, let viewController = viewController else {
            return
        }

        PostListViewController.showForBlog(blog, from: viewController, withPostStatus: status)
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

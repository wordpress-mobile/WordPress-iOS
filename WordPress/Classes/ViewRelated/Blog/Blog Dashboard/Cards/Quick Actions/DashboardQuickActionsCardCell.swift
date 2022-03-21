import UIKit
import WordPressShared

final class DashboardQuickActionsCardCell: UICollectionViewCell, Reusable, BlogDashboardCardConfigurable {

    private lazy var scrollView: ButtonScrollView = {
        let scrollView = ButtonScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = false
        return scrollView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            statsButton,
            postsButton,
            mediaButton,
            pagesButton
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = Constants.stackViewSpacing
        return stackView
    }()

    private lazy var statsButton: QuickActionButton = {
        let button = QuickActionButton(title: Strings.stats, image: .gridicon(.statsAlt))
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var postsButton: QuickActionButton = {
        let button = QuickActionButton(title: Strings.posts, image: .gridicon(.posts))
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var mediaButton: QuickActionButton = {
        let button = QuickActionButton(title: Strings.media, image: .gridicon(.image))
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var pagesButton: QuickActionButton = {
        let button = QuickActionButton(title: Strings.pages, image: .gridicon(.pages))
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        guard let viewController = viewController else {
            return
        }

        configureQuickActionButtons(for: blog, with: viewController)
    }
}

// MARK: - Button Actions

extension DashboardQuickActionsCardCell {

    private func configureQuickActionButtons(for blog: Blog, with sourceController: UIViewController) {
        statsButton.onTap = { [weak self] in
            self?.showStats(for: blog, from: sourceController)
        }

        postsButton.onTap = { [weak self] in
            self?.showPostList(for: blog, from: sourceController)
        }

        mediaButton.onTap = { [weak self] in
            self?.showMediaLibrary(for: blog, from: sourceController)
        }

        pagesButton.onTap = { [weak self] in
            self?.showPageList(for: blog, from: sourceController)
        }
    }

    private func showStats(for blog: Blog, from sourceController: UIViewController) {
        trackQuickActionsEvent(.statsAccessed, blog: blog)
        StatsViewController.show(for: blog, from: sourceController, showTodayStats: false)
    }

    private func showPostList(for blog: Blog, from sourceController: UIViewController) {
        trackQuickActionsEvent(.openedPosts, blog: blog)
        PostListViewController.showForBlog(blog, from: sourceController)
    }

    private func showMediaLibrary(for blog: Blog, from sourceController: UIViewController) {
        trackQuickActionsEvent(.openedMediaLibrary, blog: blog)
        MediaLibraryViewController.showForBlog(blog, from: sourceController)
    }

    private func showPageList(for blog: Blog, from sourceController: UIViewController) {
        trackQuickActionsEvent(.openedPages, blog: blog)
        PageListViewController.showForBlog(blog, from: sourceController)
    }

    private func trackQuickActionsEvent(_ event: WPAnalyticsStat, blog: Blog) {
        WPAppAnalytics.track(event, withProperties: [WPAppAnalyticsKeyTabSource: "dashboard", WPAppAnalyticsKeyTapSource: "quick_actions"], with: blog)
    }
}

extension DashboardQuickActionsCardCell {

    private func setup() {
        contentView.addSubview(scrollView)
        contentView.pinSubviewToAllEdges(scrollView, priority: Constants.constraintPriority)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.heightAnchor.constraint(equalTo: contentView.heightAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: Constants.stackViewHorizontalPadding),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -Constants.stackViewHorizontalPadding),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])
    }
}

extension DashboardQuickActionsCardCell {

    private enum Strings {
        static let stats = NSLocalizedString("Stats", comment: "Noun. Title for stats button.")
        static let posts = NSLocalizedString("Posts", comment: "Noun. Title for posts button.")
        static let media = NSLocalizedString("Media", comment: "Noun. Title for media button.")
        static let pages = NSLocalizedString("Pages", comment: "Noun. Title for pages button.")
    }

    private enum Constants {
        static let contentViewCornerRadius = 8.0
        static let stackViewSpacing = 16.0
        static let stackViewHorizontalPadding = 20.0
        static let constraintPriority = UILayoutPriority(999)
    }
}

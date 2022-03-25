import UIKit
import WordPressShared

class DashboardStatsCardCell: UICollectionViewCell, Reusable {

    // MARK: Private Variables

    private var viewModel: DashboardStatsViewModel?

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Constants.spacing
        return stackView
    }()

    // MARK: Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(stackView)
        contentView.pinSubviewToAllEdges(stackView, priority: Constants.constraintPriority)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

// MARK: BlogDashboardCardConfigurable

extension DashboardStatsCardCell: BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        guard let viewController = viewController, let apiResponse = apiResponse else {
            return
        }

        self.viewModel = DashboardStatsViewModel(apiResponse: apiResponse)

        clearFrames()
        addTodayStatsCard(for: blog, in: viewController)
    }

    /// Remove any card frame, if present
    private func clearFrames() {
        stackView.removeAllSubviews()
    }

    private func addTodayStatsCard(for blog: Blog, in viewController: UIViewController) {
        let frameView = BlogDashboardCardFrameView()
        frameView.title = Strings.statsTitle
        frameView.icon = UIImage.gridicon(.statsAlt, size: Constants.iconSize)
        frameView.onViewTap = { [weak self] in
            self?.showStats(for: blog, from: viewController)
        }

        let views = statsViews()
        let statsStackview = createStatsStackView(arrangedSubviews: views)
        frameView.add(subview: statsStackview)

        if viewModel?.shouldDisplayNudge ?? false {
            let nudgeButton = createNudgeButton(for: blog, in: viewController)
            frameView.add(subview: nudgeButton)
        }

        stackView.addArrangedSubview(frameView)

        WPAnalytics.track(.dashboardCardShown,
                          properties: ["type": DashboardCard.todaysStats.rawValue],
                          blog: blog)
    }

    private func createStatsStackView(arrangedSubviews: [UIView]) -> UIStackView {
        let stackview = UIStackView(arrangedSubviews: arrangedSubviews)
        stackview.axis = .horizontal
        stackview.translatesAutoresizingMaskIntoConstraints = false
        stackview.distribution = .fillEqually
        stackview.isLayoutMarginsRelativeArrangement = true
        stackview.directionalLayoutMargins = Constants.statsStackViewMargins
        stackview.isAccessibilityElement = true
        stackview.accessibilityTraits = .button
        stackview.accessibilityLabel = statsStackViewAccessibilityLabel()
        return stackview
    }

    private func statsViews() -> [UIView] {
        let viewsStatsView = DashboardSingleStatView(countString: viewModel?.todaysViews ?? "0", title: Strings.viewsTitle)
        let visitorsStatsView = DashboardSingleStatView(countString: viewModel?.todaysVisitors ?? "0", title: Strings.visitorsTitle)
        let likesStatsView = DashboardSingleStatView(countString: viewModel?.todaysLikes ?? "0", title: Strings.likesTitle)
        return [viewsStatsView, visitorsStatsView, likesStatsView]
    }

    private func statsStackViewAccessibilityLabel() -> String {
        guard let viewModel = viewModel else {
            return Strings.errorTitle
        }
        let arguments = [viewModel.todaysViews.accessibilityLabel ?? viewModel.todaysViews,
                         viewModel.todaysVisitors.accessibilityLabel ?? viewModel.todaysVisitors,
                         viewModel.todaysLikes.accessibilityLabel ?? viewModel.todaysLikes]
        return String(format: Strings.accessibilityLabelFormat, arguments: arguments)
    }

    private func showStats(for blog: Blog, from sourceController: UIViewController) {
        WPAnalytics.track(.dashboardCardItemTapped,
                          properties: ["type": DashboardCard.todaysStats.rawValue],
                          blog: blog)
        StatsViewController.show(for: blog, from: sourceController, showTodayStats: true)
        WPAppAnalytics.track(.statsAccessed, withProperties: [WPAppAnalyticsKeyTabSource: "dashboard", WPAppAnalyticsKeyTapSource: "todays_stats_card"], with: blog)
    }

    private func createNudgeButton(for blog: Blog, in viewController: UIViewController) -> DashboardStatsNudgeButton {
        let nudgeButton = DashboardStatsNudgeButton(title: Strings.nudgeButtonTitle)
        nudgeButton.contentEdgeInsets = Constants.nudgeButtonMargins

        nudgeButton.onTap = { [weak self] in
            self?.showNudgeHint(for: blog, from: viewController)
        }

        return nudgeButton
    }

    private func showNudgeHint(for blog: Blog, from sourceController: UIViewController) {
        guard let url = URL(string: Constants.nudgeURLString) else {
            return
        }

        let webViewController = WebViewControllerFactory.controller(url: url, source: "dashboard_stats_card")
        let navController = UINavigationController(rootViewController: webViewController)
        sourceController.present(navController, animated: true)
    }
}

// MARK: Constants

private extension DashboardStatsCardCell {

    enum Strings {
        static let statsTitle = NSLocalizedString("Today's Stats", comment: "Title for the card displaying today's stats.")
        static let viewsTitle = NSLocalizedString("Views", comment: "Today's Stats 'Views' label")
        static let visitorsTitle = NSLocalizedString("Visitors", comment: "Today's Stats 'Visitors' label")
        static let likesTitle = NSLocalizedString("Likes", comment: "Today's Stats 'Likes' label")
        static let commentsTitle = NSLocalizedString("Comments", comment: "Today's Stats 'Comments' label")
        static let accessibilityLabelFormat = "\(viewsTitle) %@, \(visitorsTitle) %@, \(likesTitle) %@."
        static let errorTitle = NSLocalizedString("Stats not loaded", comment: "The loading view title displayed when an error occurred")
        static let nudgeButtonTitle = NSLocalizedString("If you want to try get more views and traffic check out our top tips", comment: "Title for a button that opens up the 'Getting More Views and Traffic' support page when tapped.")
    }

    enum Constants {
        static let spacing: CGFloat = 20
        static let iconSize = CGSize(width: 18, height: 18)
        static let statsStackViewMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let nudgeButtonMargins = UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16)

        static let constraintPriority = UILayoutPriority(999)

        static let nudgeURLString = "https://wordpress.com/support/getting-more-views-and-traffic/"
    }
}

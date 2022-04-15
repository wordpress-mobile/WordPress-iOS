import UIKit
import WordPressShared

class DashboardStatsCardCell: UICollectionViewCell, Reusable {

    // MARK: Private Variables

    private var viewModel: DashboardStatsViewModel?
    private var frameView: BlogDashboardCardFrameView?
    private var nudgeView: DashboardStatsNudgeView?
    private var statsStackView: DashboardStatsStackView?

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
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // MARK: Helpers

    private func commonInit() {
        contentView.addSubview(stackView)
        contentView.pinSubviewToAllEdges(stackView, priority: Constants.constraintPriority)
        addSubviews()
    }

    private func addSubviews() {
        let frameView = BlogDashboardCardFrameView()
        frameView.title = Strings.statsTitle
        frameView.icon = UIImage.gridicon(.statsAlt, size: Constants.iconSize)
        self.frameView = frameView

        let statsStackview = DashboardStatsStackView()
        frameView.add(subview: statsStackview)
        self.statsStackView = statsStackview

        let nudgeView = createNudgeView()
        frameView.add(subview: nudgeView)
        self.nudgeView = nudgeView

        stackView.addArrangedSubview(frameView)
    }

    private func createNudgeView() -> DashboardStatsNudgeView {
        DashboardStatsNudgeView(title: Strings.nudgeButtonTitle, hint: Strings.nudgeButtonHint)
    }
}

// MARK: BlogDashboardCardConfigurable

extension DashboardStatsCardCell: BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        guard let viewController = viewController, let apiResponse = apiResponse else {
            return
        }

        self.viewModel = DashboardStatsViewModel(apiResponse: apiResponse)
        configureCard(for: blog, in: viewController)
    }

    private func configureCard(for blog: Blog, in viewController: UIViewController) {

        frameView?.onViewTap = { [weak self] in
            self?.showStats(for: blog, from: viewController)
        }

        statsStackView?.views = viewModel?.todaysViews
        statsStackView?.visitors = viewModel?.todaysVisitors
        statsStackView?.likes = viewModel?.todaysLikes

        nudgeView?.onTap = { [weak self] in
            self?.showNudgeHint(for: blog, from: viewController)
        }

        nudgeView?.isHidden = !(viewModel?.shouldDisplayNudge ?? false)

        BlogDashboardAnalytics.shared.track(.dashboardCardShown,
                          properties: ["type": DashboardCard.todaysStats.rawValue],
                          blog: blog)
    }

    private func showStats(for blog: Blog, from sourceController: UIViewController) {
        WPAnalytics.track(.dashboardCardItemTapped,
                          properties: ["type": DashboardCard.todaysStats.rawValue],
                          blog: blog)
        StatsViewController.show(for: blog, from: sourceController)
        WPAppAnalytics.track(.statsAccessed, withProperties: [WPAppAnalyticsKeyTabSource: "dashboard", WPAppAnalyticsKeyTapSource: "todays_stats_card"], with: blog)
    }

    private func showNudgeHint(for blog: Blog, from sourceController: UIViewController) {
        guard let url = URL(string: Constants.nudgeURLString) else {
            return
        }

        WPAnalytics.track(.dashboardCardItemTapped,
                          properties: [
                            "type": DashboardCard.todaysStats.rawValue,
                            "sub_type": "nudge"
                          ],
                          blog: blog)

        let webViewController = WebViewControllerFactory.controller(url: url, source: "dashboard_stats_card")
        let navController = UINavigationController(rootViewController: webViewController)
        sourceController.present(navController, animated: true)
    }
}

// MARK: Constants

private extension DashboardStatsCardCell {

    enum Strings {
        static let statsTitle = NSLocalizedString("Today's Stats", comment: "Title for the card displaying today's stats.")
        static let nudgeButtonTitle = NSLocalizedString("Interested in building your audience? Check out our top tips", comment: "Title for a button that opens up the 'Getting More Views and Traffic' support page when tapped.")
        static let nudgeButtonHint = NSLocalizedString("top tips", comment: "The part of the nudge title that should be emphasized, this content needs to match a string in 'If you want to try get more...'")
    }

    enum Constants {
        static let spacing: CGFloat = 20
        static let iconSize = CGSize(width: 18, height: 18)

        static let constraintPriority = UILayoutPriority(999)

        static let nudgeURLString = "https://wordpress.com/support/getting-more-views-and-traffic/"
    }
}

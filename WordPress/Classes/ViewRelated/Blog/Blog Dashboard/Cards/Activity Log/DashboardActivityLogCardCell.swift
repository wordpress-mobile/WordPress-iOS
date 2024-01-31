import UIKit

final class DashboardActivityLogCardCell: DashboardCollectionViewCell {

    enum ActivityLogSection: CaseIterable {
        case activities
    }

    typealias DataSource = UITableViewDiffableDataSource<ActivityLogSection, Activity>
    typealias Snapshot = NSDiffableDataSourceSnapshot<ActivityLogSection, Activity>

    private(set) var blog: Blog?
    private(set) weak var presentingViewController: BlogDashboardViewController?
    private(set) lazy var dataSource = createDataSource()
    private var viewModel: DashboardActivityLogViewModel?

    let store = StoreContainer.shared.activity

    // MARK: - Views

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.setTitle(Strings.title)
        frameView.accessibilityIdentifier = "dashboard-activity-log-card-frameview"
        return frameView
    }()

    lazy var tableView: UITableView = {
        let tableView = DashboardCardTableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.isScrollEnabled = false
        tableView.backgroundColor = nil
        let activityCellNib = ActivityTableViewCell.defaultNib
        tableView.register(activityCellNib, forCellReuseIdentifier: ActivityTableViewCell.defaultReuseID)
        tableView.separatorStyle = .none
        return tableView
    }()

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        setupView()
    }

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        tableView.dataSource = nil
    }

    // MARK: - View setup

    private func setupView() {
        contentView.addSubview(cardFrameView)
        contentView.pinSubviewToAllEdges(cardFrameView, priority: .defaultHigh)

        cardFrameView.add(subview: tableView)
        tableView.delegate = self
    }

    // MARK: - BlogDashboardCardConfigurable

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        guard let apiResponse else {
            return
        }

        self.blog = blog
        self.presentingViewController = viewController
        self.viewModel = DashboardActivityLogViewModel(apiResponse: apiResponse)

        tableView.dataSource = dataSource
        updateDataSource(with: viewModel?.activitiesToDisplay ?? [])

        configureHeaderAction(for: blog)
        configureContextMenu(for: blog)

        BlogDashboardAnalytics.shared.track(.dashboardCardShown,
                                            properties: ["type": DashboardCard.activityLog.rawValue],
                                            blog: blog)
    }

    private func configureHeaderAction(for blog: Blog) {
        cardFrameView.onHeaderTap = { [weak self] in
            self?.showActivityLog(for: blog, tapSource: Constants.headerTapSource)
        }
    }

    private func configureContextMenu(for blog: Blog) {
        cardFrameView.onEllipsisButtonTap = {
            BlogDashboardAnalytics.trackContextualMenuAccessed(for: .activityLog)
        }
        cardFrameView.ellipsisButton.showsMenuAsPrimaryAction = true

        let activityAction = UIAction(title: Strings.allActivity,
                                      image: Style.allActivityImage,
                                      handler: { [weak self] _ in self?.showActivityLog(for: blog, tapSource: Constants.contextMenuTapSource) })

        // Wrap the activity action in a menu to display a divider between the activity action and hide this action.
        // https://developer.apple.com/documentation/uikit/uimenu/options/3261455-displayinline
        let activitySubmenu = UIMenu(title: String(), options: .displayInline, children: [activityAction])

        let hideThisAction = BlogDashboardHelpers.makeHideCardAction(for: .activityLog, blog: blog)

        cardFrameView.ellipsisButton.menu = UIMenu(title: String(), options: .displayInline, children: [
            activitySubmenu,
            hideThisAction
        ])
    }

    // MARK: - Navigation

    private func showActivityLog(for blog: Blog, tapSource: String) {
        guard let activityLogController = JetpackActivityLogViewController(blog: blog) else {
            return
        }
        presentingViewController?.navigationController?.pushViewController(activityLogController, animated: true)

        WPAnalytics.track(.activityLogViewed,
                          withProperties: [
                            WPAppAnalyticsKeyTapSource: tapSource
                          ])
    }

}

// MARK: - Diffable DataSource

extension DashboardActivityLogCardCell {

    private func createDataSource() -> DataSource {
        return DataSource(tableView: tableView) { (tableView, indexPath, activity) -> UITableViewCell? in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ActivityTableViewCell.defaultReuseID) as? ActivityTableViewCell else {
                return nil
            }

            let formattableActivity = FormattableActivity(with: activity)
            cell.configureCell(formattableActivity, displaysDate: true)
            return cell
        }
    }

    private func updateDataSource(with activities: [Activity]) {
        var snapshot = Snapshot()
        snapshot.appendSections(ActivityLogSection.allCases)
        snapshot.appendItems(activities, toSection: .activities)
        dataSource.apply(snapshot)
    }
}

// MARK: - UITableViewDelegate

extension DashboardActivityLogCardCell: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let activity = dataSource.itemIdentifier(for: indexPath) else {
            return
        }

        let formattableActivity = FormattableActivity(with: activity)
        presentDetailsFor(activity: formattableActivity)
    }
}

// MARK: - Helpers

extension DashboardActivityLogCardCell {

    static func shouldShowCard(for blog: Blog) -> Bool {
        guard RemoteFeatureFlag.activityLogDashboardCard.enabled(),
              blog.supports(.activity),
              !blog.isWPForTeams() else {
            return false
        }

        return true
    }
}

extension DashboardActivityLogCardCell {

    private enum Constants {
        static let headerTapSource = "activity_card_header"
        static let contextMenuTapSource = "activity_card_context_menu"
    }

    private enum Strings {
        static let title = NSLocalizedString("dashboardCard.ActivityLog.title",
                                             value: "Recent activity",
                                             comment: "Title for the Activity Log dashboard card.")
        static let allActivity = NSLocalizedString("dashboardCard.ActivityLog.contextMenu.allActivity",
                                                   value: "All activity",
                                                   comment: "Title for the Activity Log dashboard card context menu item that navigates the user to the full Activity Logs screen.")
    }

    private enum Style {
        static let allActivityImage = UIImage(systemName: "list.bullet.indent")
    }
}

import UIKit
import SwiftUI
import WordPressData
import WordPressShared
import WordPressKit

final class DashboardActivityLogCardCell: DashboardCollectionViewCell {

    private(set) var blog: Blog?
    private(set) weak var presentingViewController: BlogDashboardViewController?
    private var viewModel: DashboardActivityLogViewModel?
    private var hostingController: UIHostingController<DashboardActivityLogListView>?

    // MARK: - Views

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.setTitle(Strings.title)
        frameView.accessibilityIdentifier = "dashboard-activity-log-card-frameview"
        return frameView
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
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        hostingController = nil
    }

    // MARK: - View setup

    private func setupView() {
        contentView.addSubview(cardFrameView)
        contentView.pinSubviewToAllEdges(cardFrameView, priority: .defaultHigh)
    }

    // MARK: - BlogDashboardCardConfigurable

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        guard let apiResponse else {
            return
        }

        self.blog = blog
        self.presentingViewController = viewController
        self.viewModel = DashboardActivityLogViewModel(apiResponse: apiResponse)

        let activities = viewModel?.activitiesToDisplay ?? []
        configureHostingController(with: activities, parent: viewController)

        configureHeaderAction(for: blog)
        configureContextMenu(for: blog)

        BlogDashboardAnalytics.shared.track(.dashboardCardShown,
                                            properties: ["type": DashboardCard.activityLog.rawValue],
                                            blog: blog)
    }

    private func configureHostingController(with activities: [Activity], parent: UIViewController?) {
        guard let parent else { return }

        let listView = DashboardActivityLogListView(activities: activities) { [weak self] activity in
            self?.didSelectActivity(activity)
        }

        if let hostingController {
            hostingController.rootView = listView
        } else {
            let hostingController = UIHostingController(rootView: listView)
            hostingController.view.backgroundColor = .clear
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            hostingController.willMove(toParent: parent)
            parent.addChild(hostingController)
            cardFrameView.add(subview: hostingController.view)
            hostingController.didMove(toParent: parent)
            self.hostingController = hostingController
        }

        hostingController?.view.invalidateIntrinsicContentSize()
    }

    private func didSelectActivity(_ activity: Activity) {
        guard let blog,
              let presentingViewController else {
            return
        }

        WPAnalytics.track(.dashboardCardItemTapped,
                          properties: ["type": DashboardCard.activityLog.rawValue],
                          blog: blog)

        let detailView = ActivityLogDetailsView(activity: activity, blog: blog)
        let hostingController = UIHostingController(rootView: detailView)
        presentingViewController.navigationController?.pushViewController(hostingController, animated: true)
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
        let activityLogController = ActivityLogsViewController(blog: blog)
        presentingViewController?.navigationController?.pushViewController(activityLogController, animated: true)

        WPAnalytics.track(.activityLogViewed, withProperties: [WPAppAnalyticsKeyTapSource: tapSource])
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

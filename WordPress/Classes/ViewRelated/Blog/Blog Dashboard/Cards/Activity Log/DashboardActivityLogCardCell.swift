import UIKit

final class DashboardActivityLogCardCell: DashboardCollectionViewCell {

    private var blog: Blog?
    private weak var presentingViewController: BlogDashboardViewController?

    // MARK: - Views

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.title = Strings.title
        return frameView
    }()

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View setup

    private func setupView() {
        contentView.addSubview(cardFrameView)
        contentView.pinSubviewToAllEdges(cardFrameView, priority: .defaultHigh)
    }

    // MARK: - BlogDashboardCardConfigurable

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        self.blog = blog
        self.presentingViewController = viewController

        configureContextMenu(blog: blog)

        // FIXME: configure card using api response
        // Expecting a list of type [Activity]
    }

    private func configureContextMenu(blog: Blog) {
        cardFrameView.onEllipsisButtonTap = {
            BlogDashboardAnalytics.trackContextualMenuAccessed(for: .activityLog)
        }
        cardFrameView.ellipsisButton.showsMenuAsPrimaryAction = true


        let activityAction = UIAction(title: Strings.allActivity,
                                      image: Style.allActivityImage,
                                      handler: { _ in self.showActivityLog(for: blog) })

        // Wrap the activity action in a menu to display a divider between the activity action and hide this action.
        // https://developer.apple.com/documentation/uikit/uimenu/options/3261455-displayinline
        let activitySubmenu = UIMenu(title: String(), options: .displayInline, children: [activityAction])


        let hideThisAction = BlogDashboardHelpers.makeHideCardAction(for: .activityLog,
                                                                     siteID: blog.dotComID?.intValue ?? 0)

        cardFrameView.ellipsisButton.menu = UIMenu(title: String(), options: .displayInline, children: [
            activitySubmenu,
            hideThisAction
        ])
    }

    // MARK: - Navigation

    private func showActivityLog(for blog: Blog) {
        guard let activityLogController = JetpackActivityLogViewController(blog: blog) else {
            return
        }
        presentingViewController?.navigationController?.pushViewController(activityLogController, animated: true)
    }

}

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

    private enum Strings {
        static let title = NSLocalizedString("dashboardCard.ActivityLog.title",
                                             value: "Recent activity",
                                             comment: "Title for the Activity Log dashboard card.")
        static let allActivity = NSLocalizedString("dashboardCard.ActivityLog.contextMenu.allActivity",
                                                   value: "Recent activity",
                                                   comment: "Title for the Activity Log dashboard card.")
    }

    private enum Style {
        static let allActivityImage = UIImage(systemName: "list.bullet.indent")
    }
}

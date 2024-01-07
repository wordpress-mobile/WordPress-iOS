import Foundation

struct BlogDashboardHelpers {
    typealias Card = BlogDashboardAnalyticPropertiesProviding & BlogDashboardPersonalizable

    static func makeHideCardAction(for card: DashboardCard, blog: Blog) -> UIAction {
        Self.makeHideCardAction(for: card as Card, blog: blog)
    }

    static func makeHideCardAction(for card: Card, blog: Blog) -> UIAction {
        makeHideCardAction {
            BlogDashboardAnalytics.trackHideTapped(for: card)
            BlogDashboardPersonalizationService(siteID: blog.dotComID?.intValue ?? 0)
                .setEnabled(false, for: card)
        }
    }

    static func makeHideCardAction(_ handler: @escaping () -> Void) -> UIAction {
        UIAction(
            title: Strings.hideThis,
            image: UIImage(systemName: "minus.circle"),
            attributes: [.destructive],
            handler: { _ in handler() }
        )
    }

    private enum Strings {
        static let hideThis = NSLocalizedString("blogDashboard.contextMenu.hideThis", value: "Hide this", comment: "Title for the context menu action that hides the dashboard card.")
    }
}

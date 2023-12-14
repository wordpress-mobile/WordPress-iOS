import Foundation

protocol BlogDashboardAnalyticPropertiesProviding {

    var blogDashboardAnalyticProperties: [AnyHashable: Any] { get }
}

struct BlogDashboardHelpers {
    typealias Card = BlogDashboardPersonalizable & BlogDashboardAnalyticPropertiesProviding

    static func makeHideCardAction(for card: Card, blog: Blog) -> UIAction {
        let service = BlogDashboardPersonalizationService(siteID: blog.dotComID?.intValue ?? 0)
        return Self.makeHideCardAction {
            BlogDashboardAnalytics.trackHideTapped(for: card)
            service.setEnabled(false, for: card)
        }
    }

    static func makeHideCardAction(for card: DashboardCard, blog: Blog) -> UIAction {
        return Self.makeHideCardAction(for: card as Card, blog: blog)
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

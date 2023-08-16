import Foundation

struct BlogDashboardHelpers {
    static func makeHideCardAction(for card: DashboardCard, blog: Blog, isSiteAgnostic: Bool = false) -> UIAction {
        UIAction(
            title: Strings.hideThis,
            image: UIImage(systemName: "minus.circle"),
            attributes: [.destructive],
            handler: { _ in
                BlogDashboardAnalytics.trackHideTapped(for: card)
                let siteID = isSiteAgnostic ? nil : blog.dotComID?.intValue
                BlogDashboardPersonalizationService(siteID: siteID)
                    .setEnabled(false, for: card)
            })
    }

    private enum Strings {
        static let hideThis = NSLocalizedString("blogDashboard.contextMenu.hideThis", value: "Hide this", comment: "Title for the context menu action that hides the dashboard card.")
    }
}

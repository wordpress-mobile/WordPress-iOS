import Foundation

struct PlansTracker {
    private static let positionKey = "position_index"

    // MARK: - Dashboard Card

    static func trackFreeToPaidPlansDashboardCardShown(in position: Int) {
        let properties = [positionKey: position]
        WPAnalytics.track(.freeToPaidPlansDashboardCardShown, properties: properties)
    }

    static func trackFreeToPaidPlansDashboardCardHidden(in position: Int) {
        let properties = [positionKey: position]
        WPAnalytics.track(.freeToPaidPlansDashboardCardHidden, properties: properties)
    }

    static func trackFreeToPaidPlansDashboardCardTapped(in position: Int) {
        let properties = [positionKey: position]
        WPAnalytics.track(.freeToPaidPlansDashboardCardTapped, properties: properties)
    }

    static func trackFreeToPaidPlansDashboardCardMenuTapped(in position: Int) {
        let properties = [positionKey: position]
        WPAnalytics.track(.freeToPaidPlansDashboardCardMenuTapped, properties: properties)
    }
}

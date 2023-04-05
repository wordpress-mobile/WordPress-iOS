import Foundation

struct DomainsDashboardCardTracker {
    private static let positionKey = "position_index"

    static func trackDirectDomainsPurchaseDashboardCardShown(in position: Int) {
        let properties = [positionKey: position]
        WPAnalytics.track(.directDomainsPurchaseDashboardCardShown, properties: properties)
    }

    static func trackDirectDomainsPurchaseDashboardCardHidden(in position: Int) {
        let properties = [positionKey: position]
        WPAnalytics.track(.directDomainsPurchaseDashboardCardHidden, properties: properties)
    }

    static func trackDirectDomainsPurchaseDashboardCardTapped(in position: Int) {
        let properties = [positionKey: position]
        WPAnalytics.track(.directDomainsPurchaseDashboardCardTapped, properties: properties)
    }
}

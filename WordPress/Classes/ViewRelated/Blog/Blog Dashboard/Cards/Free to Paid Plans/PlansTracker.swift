import Foundation

struct PlansTracker {
    enum PlanSelectionType: String {
        case domainAndPlanPackage = "domain_and_plan_package"
    }

    private static let positionKey = "position_index"
    private static let planSelectionTypeKey = "plan_selection_type"

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

    // MARK: - Plan Selection

    static func trackPlanSelectionWebViewViewed(_ type: PlanSelectionType, source: String) {
        let properties = ["source": source, planSelectionTypeKey: type.rawValue]
        WPAnalytics.track(.planSelectionWebViewViewed, properties: properties)
    }

    // MARK: - Checkout

    static func trackCheckoutWebViewViewed(source: String) {
        let properties = ["source": source]
        WPAnalytics.track(.checkoutWebViewViewed, properties: properties)
    }

    // MARK: - Purchase Result

    static func trackPurchaseResult(source: String) {
        let properties = ["source": source]
        WPAnalytics.track(.domainCreditRedemptionSuccess, withProperties: properties)
    }
}

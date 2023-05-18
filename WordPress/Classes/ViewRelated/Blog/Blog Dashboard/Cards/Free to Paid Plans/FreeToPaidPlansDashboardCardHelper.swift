import Foundation

@objc final class FreeToPaidPlansDashboardCardHelper: NSObject {

    /// Checks conditions for showing free to paid plans dashboard cards
    static func shouldShowCard(
        for blog: Blog,
        isJetpack: Bool = AppConfiguration.isJetpack,
        featureFlagEnabled: Bool = RemoteFeatureFlag.freeToPaidPlansDashboardCard.enabled()
    ) -> Bool {
        guard isJetpack, featureFlagEnabled else {
            return false
        }

        /// If this propery is empty, it indicates that domain information is not yet loaded
        let hasLoadedDomains = blog.domains?.isEmpty == false
        let hasMappedDomain = blog.hasMappedDomain()
        let hasFreePlan = !blog.hasPaidPlan

        return blog.supports(.domains)
            && hasFreePlan
            && hasLoadedDomains
            && !hasMappedDomain
    }

    static func hideCard(for blog: Blog?) {
        guard let blog,
              let siteID = blog.dotComID?.intValue else {
            DDLogError("Free to Paid Plans Dashboard Card: error hiding the card.")
            return
        }

        BlogDashboardPersonalizationService(siteID: siteID)
            .setEnabled(false, for: .freeToPaidPlansDashboardCard)
    }

    @objc static func isFeatureEnabled() -> Bool {
        return AppConfiguration.isJetpack && RemoteFeatureFlag.freeToPaidPlansDashboardCard.enabled()
    }
}

import Foundation

@objc final class DomainsDashboardCardHelper: NSObject {

    /// Checks conditions for showing domain dashboard cards
    static func shouldShowCard(
        for blog: Blog,
        isJetpack: Bool = AppConfiguration.isJetpack,
        featureFlagEnabled: Bool = RemoteFeatureFlag.domainsDashboardCard.enabled()
    ) -> Bool {
        guard isJetpack, featureFlagEnabled else {
            return false
        }

        /// If this propery is empty, it indicates that domain information is not yet loaded
        let hasLoadedDomains = blog.freeDomain != nil
        let hasOtherDomains = blog.domainsList.count > 0
        let hasDomainCredit = blog.hasDomainCredit

        return blog.supports(.domains)
            && hasLoadedDomains
            && !hasOtherDomains
            && !hasDomainCredit
    }

    static func hideCard(for blog: Blog?) {
        guard let blog,
              let siteID = blog.dotComID?.intValue else {
            DDLogError("Domains Dashboard Card: error hiding the card.")
            return
        }

        BlogDashboardPersonalizationService(siteID: siteID)
            .setEnabled(false, for: .domainsDashboardCard)
    }

    @objc static func isFeatureEnabled() -> Bool {
        return AppConfiguration.isJetpack && RemoteFeatureFlag.domainsDashboardCard.enabled()
    }
}

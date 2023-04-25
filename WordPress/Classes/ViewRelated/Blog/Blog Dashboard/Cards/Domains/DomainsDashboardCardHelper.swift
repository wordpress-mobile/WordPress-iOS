import Foundation

final class DomainsDashboardCardHelper {

    /// Checks conditions for showing domain dashboard cards
    static func shouldShowCard(
        for blog: Blog,
        isJetpack: Bool = AppConfiguration.isJetpack,
        featureFlagEnabled: Bool = RemoteFeatureFlag.domainsDashboardCard.enabled()
    ) -> Bool {
        guard isJetpack, featureFlagEnabled else {
            return false
        }

        let hasOtherDomains = blog.domainsList.count > 0
        let hasDomainCredit = blog.hasDomainCredit

        return blog.supports(.domains) && !hasOtherDomains && !hasDomainCredit
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
}

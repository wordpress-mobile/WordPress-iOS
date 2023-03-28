import Foundation

final class DomainsDashboardCardHelper {

    /// Checks conditions for showing domain dashboard cards
    static func shouldShowCard(
        for blog: Blog,
        isJetpack: Bool = AppConfiguration.isJetpack,
        featureFlagEnabled: Bool = RemoteFeatureFlag.directDomainsPurchaseDashboardCard.enabled()
    ) -> Bool {
        guard isJetpack, featureFlagEnabled else {
            return false
        }

        let isHostedAtWPcom = blog.isHostedAtWPcom
        let isAtomic = blog.isAtomic()
        let isAdmin = blog.isAdmin
        let hasOtherDomains = blog.domains?.count ?? 0 > 1
        let hasDomainCredit = blog.hasDomainCredit

        return (isHostedAtWPcom || isAtomic) && isAdmin && !hasOtherDomains && !hasDomainCredit
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

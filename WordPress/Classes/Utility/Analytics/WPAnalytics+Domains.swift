import Foundation

extension WPAnalytics {

    /// Checks if the Domain Purchasing Feature Flag is enabled.
    private static var domainPurchasingEnabled: Bool {
        RemoteFeatureFlag.plansInSiteCreation.enabled()
    }

    /// Checks if the Domain Management Feature Flag is enabled.
    private static var domainManagementEnabled: Bool {
        return RemoteFeatureFlag.domainManagement.enabled()
    }

    static func domainsProperties(
        usingCredit: Bool? = nil,
        origin: SiteCreationWebViewViewOrigin? = nil,
        domainOnly: Bool? = nil
    ) -> [AnyHashable: Any] {
        var dict: [AnyHashable: Any] = [:]
        if let usingCredit {
            dict["using_credit"] = usingCredit.stringLiteral
        }
        if Self.domainPurchasingEnabled, let origin = origin {
            dict["origin"] = origin.rawValue
        }
        if let domainOnly, Self.domainManagementEnabled {
            dict["domain_only"] = domainOnly.stringLiteral
        }
        return dict
    }

    static func domainsProperties(
        for blog: Blog,
        origin: SiteCreationWebViewViewOrigin? = .menu
    ) -> [AnyHashable: Any] {
        Self.domainsProperties(
            usingCredit: blog.canRegisterDomainWithPaidPlan,
            origin: origin,
            domainOnly: nil
        )
    }
}

enum SiteCreationWebViewViewOrigin: String {
    case siteCreation = "site_creation"
    case menu
    case allDomains = "all_domains"
}

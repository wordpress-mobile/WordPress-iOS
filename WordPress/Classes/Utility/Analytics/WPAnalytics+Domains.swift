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
        for blog: Blog,
        origin: SiteCreationWebViewViewOrigin? = .menu
    ) -> [AnyHashable: Any] {
        domainsProperties(
            usingCredit: blog.canRegisterDomainWithPaidPlan,
            origin: origin,
            domainOnly: false
        )
    }

    static func domainsProperties(
        usingCredit: Bool,
        origin: SiteCreationWebViewViewOrigin? = nil,
        domainOnly: Bool = false
    ) -> [AnyHashable: Any] {
        var dict: [AnyHashable: Any] = ["using_credit": usingCredit.stringLiteral]
        if Self.domainPurchasingEnabled, let origin = origin {
            dict["origin"] = origin.rawValue
        }
        if Self.domainManagementEnabled {
            dict["domain_only"] = domainOnly.stringLiteral
        }
        return dict
    }
}

enum SiteCreationWebViewViewOrigin: String {
    case siteCreation = "site_creation"
    case menu
}

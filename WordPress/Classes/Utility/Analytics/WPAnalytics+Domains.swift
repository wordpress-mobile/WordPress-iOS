import Foundation

extension WPAnalytics {

    /// Checks if the Domain Purchasing Feature Flag and AB Experiment are enabled
    private static var domainPurchasingEnabled: Bool {
        FeatureFlag.siteCreationDomainPurchasing.enabled
    }

    static func domainsProperties(for blog: Blog, origin: SiteCreationWebViewViewOrigin? = .menu) -> [AnyHashable: Any] {
        domainsProperties(usingCredit: blog.canRegisterDomainWithPaidPlan, origin: origin)
    }

    static func domainsProperties(
        usingCredit: Bool,
        origin: SiteCreationWebViewViewOrigin?
    ) -> [AnyHashable: Any] {
        var dict: [AnyHashable: Any] = ["using_credit": usingCredit.stringLiteral]
        if Self.domainPurchasingEnabled,
           let origin = origin {
            dict["origin"] = origin.rawValue
        }
        return dict
    }
}

enum SiteCreationWebViewViewOrigin: String {
    case siteCreation = "site_creation"
    case menu
}

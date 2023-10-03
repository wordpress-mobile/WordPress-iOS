import Foundation

extension WPAnalytics {

    /// Checks if the Domain Purchasing Feature Flag and AB Experiment are enabled
    private static var domainPurchasingEnabled: Bool {
        RemoteFeatureFlag.plansInSiteCreation.enabled()
    }

    static func domainsProperties(for blog: Blog, origin: DomainPurchaseWebViewViewOrigin? = .menu) -> [AnyHashable: Any] {
        domainsProperties(usingCredit: blog.canRegisterDomainWithPaidPlan, origin: origin)
    }

    static func domainsProperties(
        usingCredit: Bool,
        origin: DomainPurchaseWebViewViewOrigin?
    ) -> [AnyHashable: Any] {
        var dict: [AnyHashable: Any] = ["using_credit": usingCredit.stringLiteral]
        if Self.domainPurchasingEnabled,
           let origin = origin {
            dict["origin"] = origin.rawValue
        }
        return dict
    }
}

enum DomainPurchaseWebViewViewOrigin: String {
    case siteCreation = "site_creation"
    case menu
}

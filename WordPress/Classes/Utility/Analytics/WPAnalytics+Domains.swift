import Foundation

extension WPAnalytics {
    static func domainsProperties(for blog: Blog) -> [AnyHashable: Any] {
        // For now we do not have the `siteCreation` route implemented so hardcoding `menu`
        domainsProperties(usingCredit: blog.canRegisterDomainWithPaidPlan, origin: .menu)
    }

    static func domainsProperties(
        usingCredit: Bool,
        origin: DomainPurchaseWebViewViewOrigin?
    ) -> [AnyHashable: Any] {
        var dict: [AnyHashable: Any] = ["using_credit": usingCredit.stringLiteral]
        if FeatureFlag.siteCreationDomainPurchasing.enabled,
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

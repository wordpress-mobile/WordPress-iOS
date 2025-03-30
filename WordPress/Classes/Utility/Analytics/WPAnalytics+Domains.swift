import Foundation
import BuildSettingsKit
import WordPressShared

extension WPAnalytics {
    @objc class var eventNamePrefix: String {
        WPAnalyticsTesting.eventNamePrefix ?? BuildSettings.current.eventNamePrefix
    }

    @objc class var explatPlatform: String {
        WPAnalyticsTesting.explatPlatform ?? BuildSettings.current.explatPlatform
    }

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
        origin: String? = nil,
        domainOnly: Bool? = nil
    ) -> [AnyHashable: Any] {
        var dict: [AnyHashable: Any] = [:]
        if let usingCredit {
            dict["using_credit"] = usingCredit.stringLiteral
        }
        if Self.domainPurchasingEnabled, let origin {
            dict["origin"] = origin
        }
        if let domainOnly, Self.domainManagementEnabled {
            dict["domain_only"] = domainOnly.stringLiteral
        }
        return dict
    }

    static func domainsProperties(
        for blog: Blog,
        origin: String?
    ) -> [AnyHashable: Any] {
        Self.domainsProperties(
            usingCredit: blog.canRegisterDomainWithPaidPlan,
            origin: origin,
            domainOnly: nil
        )
    }

    static func domainsProperties(
        for blog: Blog,
        origin: DomainsAnalyticsWebViewOrigin? = .menu
    ) -> [AnyHashable: Any] {
        Self.domainsProperties(for: blog, origin: origin?.rawValue)
    }
}

enum DomainsAnalyticsWebViewOrigin: String {
    case siteCreation = "site_creation"
    case menu
}

// TODO: remove when WPAppAnalyticsTests get rewritten, preferably in Swift
@objc final class WPAnalyticsTesting: NSObject {
    @objc static var eventNamePrefix: String?
    @objc static var explatPlatform: String?
    @objc static var appURLScheme: String?
}

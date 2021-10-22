import Foundation

extension WPAnalytics {
    static func domainsProperties(for blog: Blog) -> [AnyHashable: Any] {
        ["using_credit":  blog.canRegisterDomainWithPaidPlan.stringLiteral]
    }
}

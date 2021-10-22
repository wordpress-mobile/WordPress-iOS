import Foundation

extension WPAnalytics {
    static func domainsProperties(for blog: Blog) -> [AnyHashable: Any] {
        domainsProperties(usingCredit: blog.canRegisterDomainWithPaidPlan)
    }

    static func domainsProperties(usingCredit: Bool) -> [AnyHashable: Any] {
        ["using_credit": usingCredit.stringLiteral]
    }
}

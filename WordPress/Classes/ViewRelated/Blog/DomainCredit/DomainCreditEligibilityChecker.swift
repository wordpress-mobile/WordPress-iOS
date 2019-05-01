class DomainCreditEligibilityChecker: NSObject {
    @objc static func canRedeemDomainCredit(blog: Blog) -> Bool {
        let isHostedAtWPCom = blog.isHostedAtWPcom
        let hasDomainCredit = blog.hasDomainCredit
        let hasWPComDomain = blog.url?.matches(regex: "wordpress\\.com\\/?$").isEmpty == false
        return isHostedAtWPCom && hasDomainCredit && hasWPComDomain
    }
}

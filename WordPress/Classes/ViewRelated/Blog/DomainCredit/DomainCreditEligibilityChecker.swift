class DomainCreditEligibilityChecker: NSObject {
    @objc static func canRedeemDomainCredit(blog: Blog, isFeatureFlagOn: Bool) -> Bool {
        guard isFeatureFlagOn else {
            return false
        }
        let isHostedAtWPCom = blog.isHostedAtWPcom
        let hasDomainCredit = blog.hasDomainCredit
        let hasWPComDomain = blog.url?.matches(regex: "wordpress\\.com\\/?$").isEmpty == false
        return isHostedAtWPCom && hasDomainCredit && hasWPComDomain
    }
}

class DomainCreditEligibilityChecker: NSObject {
    @objc static func canRedeemDomainCredit(blog: Blog) -> Bool {
        return blog.isHostedAtWPcom && blog.hasDomainCredit
    }
}

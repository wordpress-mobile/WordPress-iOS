class DomainCreditEligibilityChecker: NSObject {
    @objc static func canRedeemDomainCredit(blog: Blog) -> Bool {
        // TODO: This logic is a possible duplication of `blog.canRegisterDomainWithPaidPlan`
        return (blog.isHostedAtWPcom || blog.isAtomic()) && blog.hasDomainCredit && JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled()
    }
}

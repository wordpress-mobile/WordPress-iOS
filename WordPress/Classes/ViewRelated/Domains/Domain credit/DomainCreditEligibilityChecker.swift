class DomainCreditEligibilityChecker: NSObject {
    @objc static func canRedeemDomainCredit(blog: Blog) -> Bool {
        return blog.canRegisterDomainWithPaidPlan && JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled()
    }
}

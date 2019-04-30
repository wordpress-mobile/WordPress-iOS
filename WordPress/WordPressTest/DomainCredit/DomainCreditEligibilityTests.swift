import XCTest
@testable import WordPress

class DomainCreditEligibilityTests: XCTestCase {
    private var manager: TestContextManager!
    private var mainContext: NSManagedObjectContext {
        return manager.mainContext
    }

    override func setUp() {
        super.setUp()
        manager = TestContextManager()
    }

    func testDomainCreditEligibilityWithFeatureFlagOff() {
        let blog = ModelTestHelper.insertDotComBlog(context: mainContext)
        blog.hasDomainCredit = true
        blog.isHostedAtWPcom = true
        let canRedeemDomainCredit = DomainCreditEligibilityChecker.canRedeemDomainCredit(blog: blog, isFeatureFlagOn: false)
        XCTAssertFalse(canRedeemDomainCredit)
    }

    func testDomainCreditEligibilityOnBlogWithCustomDomain() {
        let blog = ModelTestHelper.insertSelfHostedBlog(context: mainContext)
        blog.hasDomainCredit = true
        let canRedeemDomainCredit = DomainCreditEligibilityChecker.canRedeemDomainCredit(blog: blog, isFeatureFlagOn: true)
        XCTAssertFalse(canRedeemDomainCredit)
    }

    func testDomainCreditEligibilityOnSelfHostedBlog() {
        let blog = ModelTestHelper.insertDotComBlog(context: mainContext)
        blog.hasDomainCredit = true
        blog.isHostedAtWPcom = false
        let canRedeemDomainCredit = DomainCreditEligibilityChecker.canRedeemDomainCredit(blog: blog, isFeatureFlagOn: true)
        XCTAssertFalse(canRedeemDomainCredit)
    }

    func testDomainCreditEligibilityOnEligibleBlog() {
        let blog = ModelTestHelper.insertDotComBlog(context: mainContext)
        blog.hasDomainCredit = true
        blog.isHostedAtWPcom = true
        let canRedeemDomainCredit = DomainCreditEligibilityChecker.canRedeemDomainCredit(blog: blog, isFeatureFlagOn: true)
        XCTAssertTrue(canRedeemDomainCredit)
    }
}

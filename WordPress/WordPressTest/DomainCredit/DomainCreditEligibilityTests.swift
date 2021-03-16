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

    func testDomainCreditEligibilityOnBlogWithCustomDomain() {
        let blog = ModelTestHelper.insertSelfHostedBlog(context: mainContext)
        blog.hasDomainCredit = true
        let canRedeemDomainCredit = DomainCreditEligibilityChecker.canRedeemDomainCredit(blog: blog)
        XCTAssertFalse(canRedeemDomainCredit)
    }

    func testDomainCreditEligibilityOnSelfHostedBlog() {
        let blog = ModelTestHelper.insertDotComBlog(context: mainContext)
        blog.hasDomainCredit = true
        blog.isHostedAtWPcom = false
        let canRedeemDomainCredit = DomainCreditEligibilityChecker.canRedeemDomainCredit(blog: blog)
        XCTAssertFalse(canRedeemDomainCredit)
    }

    func testDomainCreditEligibilityOnEligibleBlog() {
        let blog = ModelTestHelper.insertDotComBlog(context: mainContext)
        blog.hasDomainCredit = true
        blog.isHostedAtWPcom = true
        let canRedeemDomainCredit = DomainCreditEligibilityChecker.canRedeemDomainCredit(blog: blog)
        XCTAssertTrue(canRedeemDomainCredit)
    }

    func testDomainCreditEligibilityOnAtomicBlog() {
        let blog = BlogBuilder(mainContext)
            .with(atomic: true)
            .build()
        blog.hasDomainCredit = false
        blog.isHostedAtWPcom = false
        let canRedeemDomainCredit = DomainCreditEligibilityChecker.canRedeemDomainCredit(blog: blog)
        XCTAssertFalse(canRedeemDomainCredit)
    }

    func testDomainCreditEligibilityOnEligibleAtomicBlog() {
        let blog = BlogBuilder(mainContext)
            .with(atomic: true)
            .build()
        blog.hasDomainCredit = true
        blog.isHostedAtWPcom = false
        let canRedeemDomainCredit = DomainCreditEligibilityChecker.canRedeemDomainCredit(blog: blog)
        XCTAssertTrue(canRedeemDomainCredit)
    }
}

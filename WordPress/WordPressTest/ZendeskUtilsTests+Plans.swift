import XCTest

@testable import WordPress
@testable import WordPressKit


class ZendeskUtilsPlans: XCTestCase {

    class MockAccountService: AccountService {
        override func defaultWordPressComAccount() -> WPAccount? {
            return WPAccount(context: TestContextManager.sharedInstance().mainContext)
        }
    }

    class MockPlanService: PlanService {
        var presetPlans = [Int: RemotePlanSimpleDescription]()

        override func getAllSitesNonLocalizedPlanDescriptionsForAccount(_ account: WPAccount, success: @escaping ([Int : RemotePlanSimpleDescription]) -> Void, failure: @escaping (Error?) -> Void) {
            success(presetPlans)
        }
    }

    var accountService: MockAccountService!
    var planService: MockPlanService!

    override func setUp() {
        accountService = MockAccountService(managedObjectContext: TestContextManager.sharedInstance().mainContext)
        planService = MockPlanService(managedObjectContext: TestContextManager.sharedInstance().mainContext)
    }

    override func tearDown() {
        accountService = nil
        planService = nil
    }

    func testEcommercePlanSelected() {
        // Given
        planService.presetPlans = [1: RemotePlanSimpleDescription(planID: 1, name: "eCommerce"),
                                   2: RemotePlanSimpleDescription(planID: 2, name: "Business"),
                                   3: RemotePlanSimpleDescription(planID: 3, name: "Premium"),
                                   4: RemotePlanSimpleDescription(planID: 4, name: "Personal"),
                                   5: RemotePlanSimpleDescription(planID: 5, name: "Blogger"),
                                   6: RemotePlanSimpleDescription(planID: 6, name: "Free")]
        ZendeskUtils.sharedInstance.cacheUnlocalizedSitePlans(accountService: accountService, planService: planService)
        // When
        let highestPriorityPlan = ZendeskUtils.sharedInstance.getHighestPriorityPlan()
        // Then
        XCTAssertEqual(highestPriorityPlan, "ecommerce")
    }

    func testBusinessPlanSelected() {
        // Given
        planService.presetPlans = [1: RemotePlanSimpleDescription(planID: 1, name: "Free"),
                                   2: RemotePlanSimpleDescription(planID: 2, name: "Business"),
                                   3: RemotePlanSimpleDescription(planID: 3, name: "Premium"),
                                   4: RemotePlanSimpleDescription(planID: 4, name: "Personal"),
                                   5: RemotePlanSimpleDescription(planID: 5, name: "Blogger"),
                                   6: RemotePlanSimpleDescription(planID: 6, name: "Free")]
        ZendeskUtils.sharedInstance.cacheUnlocalizedSitePlans(accountService: accountService, planService: planService)
        // When
        let highestPriorityPlan = ZendeskUtils.sharedInstance.getHighestPriorityPlan()
        // Then
        XCTAssertEqual(highestPriorityPlan, "business_professional")
    }

    func testPremiumPlanSelected() {
        // Given
        planService.presetPlans = [1: RemotePlanSimpleDescription(planID: 1, name: "Free"),
                                   2: RemotePlanSimpleDescription(planID: 2, name: "Free"),
                                   3: RemotePlanSimpleDescription(planID: 3, name: "Premium"),
                                   4: RemotePlanSimpleDescription(planID: 4, name: "Personal"),
                                   5: RemotePlanSimpleDescription(planID: 5, name: "Blogger"),
                                   6: RemotePlanSimpleDescription(planID: 6, name: "Free")]
        ZendeskUtils.sharedInstance.cacheUnlocalizedSitePlans(accountService: accountService, planService: planService)
        // When
        let highestPriorityPlan = ZendeskUtils.sharedInstance.getHighestPriorityPlan()
        // Then
        XCTAssertEqual(highestPriorityPlan, "premium")
    }

    func testPresonalPlanSelected() {
        // Given
        planService.presetPlans = [1: RemotePlanSimpleDescription(planID: 1, name: "Free"),
                                   2: RemotePlanSimpleDescription(planID: 2, name: "Free"),
                                   3: RemotePlanSimpleDescription(planID: 3, name: "Free"),
                                   4: RemotePlanSimpleDescription(planID: 4, name: "Personal"),
                                   5: RemotePlanSimpleDescription(planID: 5, name: "Blogger"),
                                   6: RemotePlanSimpleDescription(planID: 6, name: "Free")]
        ZendeskUtils.sharedInstance.cacheUnlocalizedSitePlans(accountService: accountService, planService: planService)
        // When
        let highestPriorityPlan = ZendeskUtils.sharedInstance.getHighestPriorityPlan()
        // Then
        XCTAssertEqual(highestPriorityPlan, "personal")
    }

    func testBloggerPlanSelected() {
        // Given
        planService.presetPlans = [1: RemotePlanSimpleDescription(planID: 1, name: "Free"),
                                   2: RemotePlanSimpleDescription(planID: 2, name: "Free"),
                                   3: RemotePlanSimpleDescription(planID: 3, name: "Free"),
                                   4: RemotePlanSimpleDescription(planID: 4, name: "Free"),
                                   5: RemotePlanSimpleDescription(planID: 5, name: "Blogger"),
                                   6: RemotePlanSimpleDescription(planID: 6, name: "Free")]
        ZendeskUtils.sharedInstance.cacheUnlocalizedSitePlans(accountService: accountService, planService: planService)
        // When
        let highestPriorityPlan = ZendeskUtils.sharedInstance.getHighestPriorityPlan()
        // Then
        XCTAssertEqual(highestPriorityPlan, "blogger")
    }

    func testFreePlanSelected() {
        // Given
        planService.presetPlans = [1: RemotePlanSimpleDescription(planID: 1, name: "NewPlan"),
                                   2: RemotePlanSimpleDescription(planID: 2, name: "Free")]
        ZendeskUtils.sharedInstance.cacheUnlocalizedSitePlans(accountService: accountService, planService: planService)
        // When
        let highestPriorityPlan = ZendeskUtils.sharedInstance.getHighestPriorityPlan()
        // Then
        XCTAssertEqual(highestPriorityPlan, "free")
    }

    func testNewPlanSelected() {
        // Given
        planService.presetPlans = [1: RemotePlanSimpleDescription(planID: 1, name: "NewPlan"),
                                   2: RemotePlanSimpleDescription(planID: 2, name: "NewPlan")]
        ZendeskUtils.sharedInstance.cacheUnlocalizedSitePlans(accountService: accountService, planService: planService)
        // When
        let highestPriorityPlan = ZendeskUtils.sharedInstance.getHighestPriorityPlan()
        // Then
        XCTAssertEqual(highestPriorityPlan, "newplan")
    }

    func testNoPlanSelected() {
        // Given
        planService.presetPlans = [:]
        ZendeskUtils.sharedInstance.cacheUnlocalizedSitePlans(accountService: accountService, planService: planService)
        // When
        let highestPriorityPlan = ZendeskUtils.sharedInstance.getHighestPriorityPlan()
        // Then
        XCTAssertEqual(highestPriorityPlan, "")
    }
}

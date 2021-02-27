import XCTest
import ZendeskCoreSDK

@testable import WordPress
@testable import WordPressKit


class ZendeskUtilsPlans: XCTestCase {

    class MockPlanService: PlanService {
        var presetPlans = [Int: RemotePlanSimpleDescription]()

        override func allPlans() -> [Plan] {
            let context = TestContextManager.sharedInstance().mainContext
            let freePlan = Plan(context: context)
            freePlan.supportPriority = 1
            freePlan.supportName = "free"
            freePlan.nonLocalizedShortname = "Free"
            freePlan.shortname = "Free"

            let bloggerPlan = Plan(context: context)
            bloggerPlan.supportPriority = 2
            bloggerPlan.supportName = "blogger"
            bloggerPlan.nonLocalizedShortname = "Blogger"
            bloggerPlan.shortname = "Blogger"

            let personalPlan = Plan(context: context)
            personalPlan.supportPriority = 3
            personalPlan.supportName = "personal"
            personalPlan.nonLocalizedShortname = "Personal"
            personalPlan.shortname = "Personal"

            let premiumPlan = Plan(context: context)
            premiumPlan.supportPriority = 4
            premiumPlan.supportName = "premium"
            premiumPlan.nonLocalizedShortname = "Premium"
            premiumPlan.shortname = "Premium"

            let businessPlan = Plan(context: context)
            businessPlan.supportPriority = 5
            businessPlan.supportName = "business_professional"
            businessPlan.nonLocalizedShortname = "Business"
            businessPlan.shortname = "Business"

            let ecommercePlan = Plan(context: context)
            ecommercePlan.supportPriority = 6
            ecommercePlan.supportName = "ecommerce"
            ecommercePlan.nonLocalizedShortname = "E-commerce"
            ecommercePlan.shortname = "E-commerce"

            return [freePlan, bloggerPlan, personalPlan, premiumPlan, businessPlan, ecommercePlan]

        }

        override func getAllSitesNonLocalizedPlanDescriptionsForAccount(_ account: WPAccount,
                                                                        success: @escaping ([Int: RemotePlanSimpleDescription]) -> Void,
                                                                        failure: @escaping (Error?) -> Void) {
            success(presetPlans)
        }
    }

    var contextManager: TestContextManager!
    var planService: MockPlanService!

    override func setUpWithError() throws {
        contextManager = TestContextManager()
        planService = MockPlanService(managedObjectContext: contextManager.mainContext)

        let account = WPAccount(context: contextManager.mainContext)
        account.userID = 1
        account.username = "1"
        account.authToken = "authToken"
        account.uuid = UUID().uuidString
        try contextManager.mainContext.save()

        AccountService(managedObjectContext: contextManager.mainContext).setDefaultWordPressComAccount(account)
    }

    override func tearDown() {
        planService = nil
        contextManager = nil
    }

    func testEcommercePlanSelected() {
        // Given
        planService.presetPlans = [1: RemotePlanSimpleDescription(planID: 1, name: "eCommerce"),
                                   2: RemotePlanSimpleDescription(planID: 2, name: "Business"),
                                   3: RemotePlanSimpleDescription(planID: 3, name: "Premium"),
                                   4: RemotePlanSimpleDescription(planID: 4, name: "Personal"),
                                   5: RemotePlanSimpleDescription(planID: 5, name: "Blogger"),
                                   6: RemotePlanSimpleDescription(planID: 6, name: "Free")]
        ZendeskUtils.sharedInstance.cacheUnlocalizedSitePlans(planService: planService)
        // When
        let requestFields = ZendeskUtils.sharedInstance.createRequest(planService: planService).customFields
        // Then
        XCTAssert(requestFields.contains(where: {
            return $0.fieldId == 25175963 && $0.value as! String == "ecommerce"
        }))
    }

    func testBusinessPlanSelected() {
        // Given
        planService.presetPlans = [1: RemotePlanSimpleDescription(planID: 1, name: "Free"),
                                   2: RemotePlanSimpleDescription(planID: 2, name: "Business"),
                                   3: RemotePlanSimpleDescription(planID: 3, name: "Premium"),
                                   4: RemotePlanSimpleDescription(planID: 4, name: "Personal"),
                                   5: RemotePlanSimpleDescription(planID: 5, name: "Blogger"),
                                   6: RemotePlanSimpleDescription(planID: 6, name: "Free")]
        ZendeskUtils.sharedInstance.cacheUnlocalizedSitePlans(planService: planService)
        // When
        let requestFields = ZendeskUtils.sharedInstance.createRequest(planService: planService).customFields
        // Then
        XCTAssert(requestFields.contains(where: {
            return $0.fieldId == 25175963 && $0.value as! String == "business_professional"
        }))
    }

    func testPremiumPlanSelected() {
        // Given
        planService.presetPlans = [1: RemotePlanSimpleDescription(planID: 1, name: "Free"),
                                   2: RemotePlanSimpleDescription(planID: 2, name: "Free"),
                                   3: RemotePlanSimpleDescription(planID: 3, name: "Premium"),
                                   4: RemotePlanSimpleDescription(planID: 4, name: "Personal"),
                                   5: RemotePlanSimpleDescription(planID: 5, name: "Blogger"),
                                   6: RemotePlanSimpleDescription(planID: 6, name: "Free")]
        ZendeskUtils.sharedInstance.cacheUnlocalizedSitePlans(planService: planService)
        // When
        let requestFields = ZendeskUtils.sharedInstance.createRequest(planService: planService).customFields
        // Then
        XCTAssert(requestFields.contains(where: {
            return $0.fieldId == 25175963 && $0.value as! String == "premium"
        }))
    }

    func testPresonalPlanSelected() {
        // Given
        planService.presetPlans = [1: RemotePlanSimpleDescription(planID: 1, name: "Free"),
                                   2: RemotePlanSimpleDescription(planID: 2, name: "Free"),
                                   3: RemotePlanSimpleDescription(planID: 3, name: "Free"),
                                   4: RemotePlanSimpleDescription(planID: 4, name: "Personal"),
                                   5: RemotePlanSimpleDescription(planID: 5, name: "Blogger"),
                                   6: RemotePlanSimpleDescription(planID: 6, name: "Free")]
        ZendeskUtils.sharedInstance.cacheUnlocalizedSitePlans(planService: planService)
        // When
        let requestFields = ZendeskUtils.sharedInstance.createRequest(planService: planService).customFields
        // Then
        XCTAssert(requestFields.contains(where: {
            return $0.fieldId == 25175963 && $0.value as! String == "personal"
        }))
    }

    func testBloggerPlanSelected() {
        // Given
        planService.presetPlans = [1: RemotePlanSimpleDescription(planID: 1, name: "Free"),
                                   2: RemotePlanSimpleDescription(planID: 2, name: "Free"),
                                   3: RemotePlanSimpleDescription(planID: 3, name: "Free"),
                                   4: RemotePlanSimpleDescription(planID: 4, name: "Free"),
                                   5: RemotePlanSimpleDescription(planID: 5, name: "Blogger"),
                                   6: RemotePlanSimpleDescription(planID: 6, name: "Free")]
        ZendeskUtils.sharedInstance.cacheUnlocalizedSitePlans(planService: planService)
        // When
        let requestFields = ZendeskUtils.sharedInstance.createRequest(planService: planService).customFields
        // Then
        XCTAssert(requestFields.contains(where: {
            return $0.fieldId == 25175963 && $0.value as! String == "blogger"
        }))
    }

    func testFreePlanSelected() {
        // Given
        planService.presetPlans = [1: RemotePlanSimpleDescription(planID: 1, name: "NewPlan"),
                                   2: RemotePlanSimpleDescription(planID: 2, name: "Free")]
        ZendeskUtils.sharedInstance.cacheUnlocalizedSitePlans(planService: planService)
        // When
        let requestFields = ZendeskUtils.sharedInstance.createRequest(planService: planService).customFields
        // Then
        XCTAssert(requestFields.contains(where: {
            return $0.fieldId == 25175963 && $0.value as! String == "free"
        }))
    }

    func testNoPlanSelected() {
        // Given
        planService.presetPlans = [:]
        ZendeskUtils.sharedInstance.cacheUnlocalizedSitePlans(planService: planService)
        // When
        let requestFields = ZendeskUtils.sharedInstance.createRequest(planService: planService).customFields
        // Then
        XCTAssert(requestFields.contains(where: {
            return $0.fieldId == 25175963 && $0.value as! String == ""
        }))
    }
}

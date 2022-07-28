import XCTest
import ZendeskCoreSDK

@testable import WordPress
@testable import WordPressKit


class ZendeskUtilsPlans: XCTestCase {

    class MockPlanServiceRemote: PlanServiceRemote {
        let plans = ["ecommerce", "business_professional", "premium", "personal", "blogger", "free", "add_on_plan"]
        let addOns = ["jetpack_addon_scan_daily"]

        var planIndex = 0

        override func getZendeskMetadata(siteID: Int, completion: @escaping (Result<ZendeskMetadata, Error>) -> Void) {

            let metadata = ZendeskMetadata(plan: plans[planIndex], jetpackAddons: planIndex == 6 ? ["jetpack_addon_scan_daily"] : [])

            completion(.success(metadata))

        }
    }

    var planServiceRemote: MockPlanServiceRemote!

    override func setUp() {
        planServiceRemote = MockPlanServiceRemote(wordPressComRestApi: MockWordPressComRestApi())
    }

    override func tearDown() {
        planServiceRemote = nil
    }

    func testEcommercePlanSelected() {
        // Given
        planServiceRemote.planIndex = 0
        // When
        ZendeskUtils.sharedInstance.createRequest(planServiceRemote: planServiceRemote, siteID: 0) { requestConfiguration in
            let requestFields = requestConfiguration.customFields
            // Then
            XCTAssert(requestFields.contains(where: {
                return $0.fieldId == 25175963 && $0.value as! String == "ecommerce"
            }))

            XCTAssert(requestFields.contains(where: {
                return $0.fieldId == 360025010672 && $0.value as! [String] == []
            }))
        }
    }

    func testBusinessPlanSelected() {
        // Given
        planServiceRemote.planIndex = 1
        // When
        ZendeskUtils.sharedInstance.createRequest(planServiceRemote: planServiceRemote, siteID: 0) { requestConfiguration in
            let requestFields = requestConfiguration.customFields

            // Then
            XCTAssert(requestFields.contains(where: {
                return $0.fieldId == 25175963 && $0.value as! String == "business_professional"
            }))

            XCTAssert(requestFields.contains(where: {
                return $0.fieldId == 360025010672 && $0.value as! [String] == []
            }))
        }
    }

    func testPremiumPlanSelected() {
        // Given
        planServiceRemote.planIndex = 2
        // When
        ZendeskUtils.sharedInstance.createRequest(planServiceRemote: planServiceRemote, siteID: 0) { requestConfiguration in
            let requestFields = requestConfiguration.customFields
            // Then
            XCTAssert(requestFields.contains(where: {
                return $0.fieldId == 25175963 && $0.value as! String == "premium"
            }))

            XCTAssert(requestFields.contains(where: {
                return $0.fieldId == 360025010672 && $0.value as! [String] == []
            }))
        }
    }

    func testPresonalPlanSelected() {
        // Given
        planServiceRemote.planIndex = 3
        // When
        ZendeskUtils.sharedInstance.createRequest(planServiceRemote: planServiceRemote, siteID: 0) { requestConfiguration in
            let requestFields = requestConfiguration.customFields
            // Then
            XCTAssert(requestFields.contains(where: {
                return $0.fieldId == 25175963 && $0.value as! String == "personal"
            }))

            XCTAssert(requestFields.contains(where: {
                return $0.fieldId == 360025010672 && $0.value as! [String] == []
            }))
        }
    }

    func testBloggerPlanSelected() {
        // Given
        planServiceRemote.planIndex = 4
        // When
        ZendeskUtils.sharedInstance.createRequest(planServiceRemote: planServiceRemote, siteID: 0) { requestConfiguration in
            let requestFields = requestConfiguration.customFields
            // Then
            XCTAssert(requestFields.contains(where: {
                return $0.fieldId == 25175963 && $0.value as! String == "blogger"
            }))

            XCTAssert(requestFields.contains(where: {
                return $0.fieldId == 360025010672 && $0.value as! [String] == []
            }))
        }
    }

    func testFreePlanSelected() {
        // Given
        planServiceRemote.planIndex = 5
        // When
        ZendeskUtils.sharedInstance.createRequest(planServiceRemote: planServiceRemote, siteID: 0) { requestConfiguration in
            let requestFields = requestConfiguration.customFields
            // Then
            XCTAssert(requestFields.contains(where: {
                return $0.fieldId == 25175963 && $0.value as! String == "free"
            }))

            XCTAssert(requestFields.contains(where: {
                return $0.fieldId == 360025010672 && $0.value as! [String] == []
            }))
        }
    }

    func testAddOnPlanSelected() {
        // Given
        planServiceRemote.planIndex = 6
        // When
        ZendeskUtils.sharedInstance.createRequest(planServiceRemote: planServiceRemote, siteID: 0) { requestConfiguration in
            let requestFields = requestConfiguration.customFields
            // Then
            XCTAssert(requestFields.contains(where: {
                return $0.fieldId == 25175963 && $0.value as! String == "add_on_plan"
            }))

            XCTAssert(requestFields.contains(where: {
                return $0.fieldId == 360025010672 && $0.value as! [String] == ["jetpack_addon_scan_daily"]
            }))
        }
    }
}

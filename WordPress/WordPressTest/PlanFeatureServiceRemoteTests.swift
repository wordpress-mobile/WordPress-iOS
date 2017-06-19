@testable import WordPress

class PlanFeatureServiceRemoteTests: RemoteTestCase, RESTTestable {

    // MARK: - Constants

    let planFeaturesEndpoint = "plans/features"

    let getPlanFeaturesSuccessMockFilename          = "plans-feature-success.json"
    let getPlanFeaturesEmptySuccessMockFilename     = "plans-feature-empty-success.json"
    let getPlanFeaturesBadJsonFailureMockFilename   = "plans-feature-bad-json-failure.json"


    // MARK: - Properties

    var remote: PlanFeatureServiceRemote!

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()

        remote = PlanFeatureServiceRemote(wordPressComRestApi: getRestApi())
        clearDiskCache()
    }

    override func tearDown() {
        super.tearDown()

        remote = nil
    }

    // MARK: - Get Plans Tests

    func testGetPlanFeaturesSucceeds() {
        let expect = expectation(description: "Get plan features success")

        stubRemoteResponse(planFeaturesEndpoint, filename: getPlanFeaturesSuccessMockFilename, contentType: .ApplicationJSON)
        remote.getPlanFeatures({ planFeatures in
            XCTAssertEqual(planFeatures.count, 11, "The plan features count should be 11")
            expect.fulfill()
        }) { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetPlanFeaturesWithEmptyResponseArraySucceeds() {
        let expect = expectation(description: "Get plan features with empty response array success")

        stubRemoteResponse(planFeaturesEndpoint, filename: getPlanFeaturesEmptySuccessMockFilename, contentType: .ApplicationJSON)
        remote.getPlanFeatures({ planFeatures in
            expect.fulfill()
        }, failure: { error in
            XCTFail("getPlanFeatures should not fail when empty.")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetPlanFeaturesWithServerErrorFails() {
        let expect = expectation(description: "Get plan features server error failure")

        stubRemoteResponse(planFeaturesEndpoint, data: Data(), contentType: .NoContentType, status: 500)
        remote.getPlanFeatures({ planFeatures in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiError.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }


    func testGetPlanFeaturesWithBadJsonFails() {
        let expect = expectation(description: "Get plan features with invalid json response failure")

        stubRemoteResponse(planFeaturesEndpoint, filename: getPlanFeaturesBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.getPlanFeatures({ planFeatures in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }
}

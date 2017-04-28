@testable import WordPress

class PlanFeatureServiceRemoteTests: RemoteTestCase {

    // MARK: - Constants

    let planFeaturesEndpoint = "plans/features"

    let getPlanFeaturesSuccessMockFilename          = "plans-feature-success.json"
    let getPlanFeaturesEmptyFailureMockFilename     = "plans-feature-empty-success.json"
    let getPlanFeaturesBadJsonFailureMockFilename   = "plans-feature-bad-json-failure.json"


    // MARK: - Properties

    var remote: PlanFeatureServiceRemote!

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()

        remote = PlanFeatureServiceRemote(wordPressComRestApi: restApi)
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Get Plans Tests

    func testGetPlansSucceeds() {
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

    func testGetPlansWithEmptyResponseArraySucceeds() {
        let expect = expectation(description: "Get plans with empty response array success")

        stubRemoteResponse(planFeaturesEndpoint, filename: getPlanFeaturesEmptyFailureMockFilename, contentType: .ApplicationJSON)
        remote.getPlanFeatures({ planFeatures in
            expect.fulfill()
        }, failure: { error in
            XCTFail("The getPlanFeatures should not fail when empty.")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

//    func testGetPlansWithBadSiteFails() {
//        let expect = expectation(description: "Get plans with incorrect site failure")
//
//        stubRemoteResponse(sitePlansEndpoint, filename: getPlansBadSiteFailureMockFilename, contentType: .ApplicationJSON, status: 403)
//        remote.getPlansForSite(siteID, success: { sitePlans in
//            XCTFail("This callback shouldn't get called")
//            expect.fulfill()
//        }, failure: { error in
//            let error = error as NSError
//            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
//            XCTAssertEqual(error.code, WordPressComRestApiError.authorizationRequired.rawValue, "The error code should be 2 - authorization_required")
//            expect.fulfill()
//        })
//
//        waitForExpectations(timeout: timeout, handler: nil)
//    }
//
//    func testGetPlansWithServerErrorFails() {
//        let expect = expectation(description: "Get plans server error failure")
//
//        stubRemoteResponse(sitePlansEndpoint, data: Data(), contentType: .NoContentType, status: 500)
//        remote.getPlansForSite(siteID, success: { sitePlans in
//            XCTFail("This callback shouldn't get called")
//            expect.fulfill()
//        }, failure: { error in
//            let error = error as NSError
//            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
//            XCTAssertEqual(error.code, WordPressComRestApiError.unknown.rawValue, "The error code should be 7 - unknown")
//            expect.fulfill()
//        })
//
//        waitForExpectations(timeout: timeout, handler: nil)
//    }
//
//    func testGetPlansWithBadAuthFails() {
//        let expect = expectation(description: "Get plans with bad auth failure")
//
//        stubRemoteResponse(sitePlansEndpoint, filename: getPlansAuthFailureMockFilename, contentType: .ApplicationJSON, status: 403)
//        remote.getPlansForSite(siteID, success: { sitePlans in
//            XCTFail("This callback shouldn't get called")
//            expect.fulfill()
//        }, failure: { error in
//            let error = error as NSError
//            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
//            XCTAssertEqual(error.code, WordPressComRestApiError.authorizationRequired.rawValue, "The error code should be 2 - authorization_required")
//            expect.fulfill()
//        })
//
//        waitForExpectations(timeout: timeout, handler: nil)
//    }
//
//    func testGetPlansWithBadJsonFails() {
//        let expect = expectation(description: "Get plans with invalid json response failure")
//
//        stubRemoteResponse(sitePlansEndpoint, filename: getPlansBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
//        remote.getPlansForSite(siteID, success: { sitePlans in
//            XCTFail("This callback shouldn't get called")
//            expect.fulfill()
//        }, failure: { error in
//            expect.fulfill()
//        })
//
//        waitForExpectations(timeout: timeout, handler: nil)
//    }
}

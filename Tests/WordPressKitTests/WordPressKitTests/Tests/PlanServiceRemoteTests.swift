import Foundation
import XCTest
@testable import WordPressKit

class PlanServiceRemoteTests: RemoteTestCase, RESTTestable {

    // MARK: - Constants

    let siteID   = 321

    let getPlansBadJsonFailureMockFilename               = "site-plans-bad-json-failure.json"
    let getPlansSuccessMockFilename_ApiVersion1_3        = "site-plans-v3-success.json"
    let getPlansEmptyFailureMockFilename_ApiVersion1_3   = "site-plans-v3-empty-failure.json"
    let getPlansBadJsonFailureMockFilename_ApiVersion1_3 = "site-plans-v3-bad-json-failure.json"
    let getWpcomPlansSuccessMockFilename                 = "plans-mobile-success.json"
    let getPlansMeSitesSuccessMockFilename               = "plans-me-sites-success.json"
    let getZendeskMetadataSuccessMockFilename            = "site-zendesk-metadata-success.json"

    // MARK: - Properties

    var sitePlansEndpoint: String { return "sites/\(siteID)/plans" }
    var plansMobileEndpoint = "plans/mobile"
    var meSitesEndpoint = "me/sites"

    var remote: PlanServiceRemote!
    var remoteV3: PlanServiceRemote_ApiVersion1_3!

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()

        remote = PlanServiceRemote(wordPressComRestApi: getRestApi())
        remoteV3 = PlanServiceRemote_ApiVersion1_3(wordPressComRestApi: getRestApi())
    }

    override func tearDown() {
        super.tearDown()

        remote = nil
    }

    // MARK: - v1.3 Plans Tests

    func testGetPlansSucceeds_ApiVersion1_3() {
        let expect = expectation(description: "Get plans for site success")

        stubRemoteResponse(sitePlansEndpoint, filename: getPlansSuccessMockFilename_ApiVersion1_3, contentType: .ApplicationJSON)

        remoteV3.getPlansForSite(siteID, success: { sitePlans in
            XCTAssertEqual(sitePlans.activePlan.hasDomainCredit, true, "Active plan should have domain credit")
            XCTAssertEqual(sitePlans.availablePlans.count, 7, "The availible plans count should be 7")
            expect.fulfill()
        }) { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetPlansWithEmptyResponseArrayFails_ApiVersion1_3() {
        let expect = expectation(description: "Get plans with empty response array success")

        stubRemoteResponse(sitePlansEndpoint, filename: getPlansEmptyFailureMockFilename_ApiVersion1_3, contentType: .ApplicationJSON)
        remoteV3.getPlansForSite(siteID, success: { _ in
            XCTFail("The site should always return plans.")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, String(reflecting: PlanServiceRemote.ResponseError.self), "The error domain should be PlanServiceRemote.ResponseError")
            XCTAssertEqual(error.code, PlanServiceRemote.ResponseError.noActivePlan.rawValue, "The error code should be 2 - no active plan")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetPlansWithBadJsonFails_ApiVersion1_3() {
        let expect = expectation(description: "Get plans with invalid json response failure")

        stubRemoteResponse(sitePlansEndpoint, filename: getPlansBadJsonFailureMockFilename_ApiVersion1_3, contentType: .ApplicationJSON, status: 200)
        remoteV3.getPlansForSite(siteID, success: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { _ in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: - v2 plans/mobile Tests

    func testGetWpcomPlansSucceeds() {
        let expect = expectation(description: "Get wpcom plans success")

        stubRemoteResponse(plansMobileEndpoint, filename: getWpcomPlansSuccessMockFilename, contentType: .ApplicationJSON)

        remote.getWpcomPlans({ plans in
            XCTAssertEqual(plans.plans.count, 6, "The number of plans returned should be 6.")
            XCTAssertEqual(plans.features.count, 33, "The number of features returned should be 33.")
            XCTAssertEqual(plans.groups.count, 2, "The number of groups returned should be 2.")

            expect.fulfill()
        }) { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetWpcomPlansWithServerErrorFails() {
        let expect = expectation(description: "Get plans server error failure")

        stubRemoteResponse(plansMobileEndpoint, data: Data(), contentType: .NoContentType, status: 500)
        remote.getWpcomPlans({ _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiErrorCode.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetWpcomPlansWithBadJsonFails() {
        let expect = expectation(description: "Get plans with invalid json response failure")

        stubRemoteResponse(plansMobileEndpoint, filename: getPlansBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.getWpcomPlans({ _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { _ in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testParseWpcomPlan() {
        let str = """
        {
            "groups": [
                "personal",
                "business"
            ],
            "products": [
                {
                    "plan_id": 1003
                },
                {
                    "plan_id": 1023
                }
            ],
            "name": "WordPress.com Premium",
            "short_name": "Premium",
            "support_priority": 4,
            "support_name": "premium",
            "nonlocalized_short_name": "Premium",
            "tagline": "Best for Entrepreneurs and Freelancers",
            "description": "Build a unique website with advanced design tools, CSS editing, lots of space for audio and video, and the ability to monetize your site with ads.",
            "features": [
                "custom-domain",
                "jetpack-essentials",
                "support-live",
                "themes-premium",
                "design-custom",
                "space-13G",
                "no-ads",
                "simple-payments",
                "wordads",
                "videopress"
            ],
            "icon": ""
        }
        """
        let data = str.data(using: .utf8)!
        let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as! [String: AnyObject]
        XCTAssertNotNil(remote.parseWpcomPlan(json))
    }

    func testParseWpcomGroup() {
        let str = """
        {
            "slug": "personal",
            "name": "Personal"
        }
        """
        let data = str.data(using: .utf8)!
        let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as! [String: AnyObject]
        XCTAssertNotNil(remote.parsePlanGroup(json))
    }

    func testParseWpcomFeature() {
        let str = """
        {
            "id": "subdomain",
            "name": "WordPress.com Subdomain",
            "description": "Your site address will use a WordPress.com subdomain (sitename.wordpress.com)."
        }
        """
        let data = str.data(using: .utf8)!
        let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as! [String: AnyObject]
        XCTAssertNotNil(remote.parsePlanFeature(json))
    }

    func testUnexpectedJsonFormatYieldsNil() {
        let str = """
        {
            "key": "unexpected json"
        }
        """
        let data = str.data(using: .utf8)!
        let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as! [String: AnyObject]
        XCTAssertNil(remote.parseWpcomPlan(json))
        XCTAssertNil(remote.parsePlanGroup(json))
        XCTAssertNil(remote.parsePlanFeature(json))
    }

    // MARK: - Test Plan Descriptions

    func testPlanDescriptionsForAllSitesForLocale() {
        let expect = expectation(description: "Get plan descriptions success")
        stubRemoteResponse(meSitesEndpoint, filename: getPlansMeSitesSuccessMockFilename, contentType: .ApplicationJSON)

        remote.getPlanDescriptionsForAllSitesForLocale("en", success: { (response) in
            XCTAssertEqual(response.count, 5)
            expect.fulfill()
        }) { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testPlanDescriptionsForAllSitesFailure() {
        let expect = expectation(description: "Get plan descriptions failure")
        stubRemoteResponse(meSitesEndpoint, data: Data(), contentType: .NoContentType, status: 500)

        remote.getPlanDescriptionsForAllSitesForLocale("en", success: { (_) in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }) { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiErrorCode.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testParsePlanDescriptions() {
        let jetpackFlag = " (Jetpack)"

        let str1 = """
        {
            "ID": 1,
            "plan": {
                "product_id": 2002,
                "product_slug": "jetpack_free",
                "product_name_short": "Free"
            }
        }
        """
        let data1 = str1.data(using: .utf8)!
        let json1 = (try? JSONSerialization.jsonObject(with: data1, options: [])) as! [String: AnyObject]

        let result = remote.parsePlanDescriptionForSite(json1)!

        XCTAssertEqual(result.siteID, 1)
        XCTAssertTrue(result.plan.name.contains(jetpackFlag))

        let str2 = """
        {
            "ID": 2,
            "plan": {
                "product_id": 1,
                "product_slug": "free",
                "product_name_short": "Free"
            }
        }
        """
        let data2 = str2.data(using: .utf8)!
        let json2 = (try? JSONSerialization.jsonObject(with: data2, options: [])) as! [String: AnyObject]

        let result2 = remote.parsePlanDescriptionForSite(json2)!

        XCTAssertEqual(result2.siteID, 2)
        XCTAssertFalse(result2.plan.name.contains(jetpackFlag))
    }

    // MARK: - Zendesk

    func testZendeskMetadata() throws {
        stubRemoteResponse("rest/v1.1/me/sites?fields=ID%2C%20zendesk_site_meta", filename: getZendeskMetadataSuccessMockFilename, contentType: .ApplicationJSON, status: 200)

        var result: Result<ZendeskMetadata, Error>? = nil
        let completed = expectation(description: "API call completed")
        remote.getZendeskMetadata(siteID: 123, completion: {
            result = $0
            completed.fulfill()
        })
        wait(for: [completed], timeout: 0.3)

        try XCTAssertEqual(XCTUnwrap(result).get().plan, "free")
    }

    func testZendeskMetadataSiteNotFound() throws {
        stubRemoteResponse("rest/v1.1/me/sites?fields=ID%2C%20zendesk_site_meta", filename: getZendeskMetadataSuccessMockFilename, contentType: .ApplicationJSON, status: 200)

        var result: Result<ZendeskMetadata, Error>? = nil
        let completed = expectation(description: "API call completed")
        remote.getZendeskMetadata(siteID: 9999, completion: {
            result = $0
            completed.fulfill()
        })
        wait(for: [completed], timeout: 0.3)

        switch try XCTUnwrap(result) {
        case .failure(PlanServiceRemoteError.noMetadata):
            XCTAssertTrue(true)
        default:
            XCTFail("Unexpected result: \(String(describing: result))")
        }
    }
}

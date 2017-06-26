import Foundation
import XCTest
@testable import WordPressKit

class SiteManagementServiceRemoteTests: RemoteTestCase, RESTTestable {

    // MARK: - Constants

    let siteID = 321

    let deleteSiteSuccessMockFilename                       = "site-delete-success.json"
    let deleteSiteAuthFailureMockFilename                   = "site-delete-auth-failure.json"
    let deleteSiteBadJsonFailureMockFilename                = "site-delete-bad-json-failure.json"
    let deleteSiteUnexpectedJsonFailureMockFilename         = "site-delete-unexpected-json-failure.json"
    let deleteSiteMissingStatusJsonFailureMockFilename      = "site-delete-missing-status-failure.json"

    let exportContentSuccessMockFilename                    = "site-export-success.json"
    let exportContentFailureMockFilename                    = "site-export-failure.json"
    let exportContentAuthFailureMockFilename                = "site-export-auth-failure.json"
    let exportContentBadJsonFailureMockFilename             = "site-export-bad-json-failure.json"
    let exportContentMissingStatusJsonFailureMockFilename   = "site-export-missing-status-failure.json"

    let getActivePurchasesSuccessMockFilename               = "site-active-purchases-two-active-success.json"
    let getActivePurchasesWithNoneActiveMockFilename        = "site-active-purchases-none-active-success.json"
    let getActivePurchasesWithEmptyResponseMockFilename     = "site-active-purchases-empty-response.json"
    let getActivePurchasesAuthFailureMockFilename           = "site-active-purchases-auth-failure.json"
    let getActivePurchasesBadJsonFailureMockFilename        = "site-active-purchases-bad-json-failure.json"

    // MARK: - Properties

    var siteDeleteEndpoint: String { return "sites/\(siteID)/delete" }
    var siteExportStartEndpoint: String { return "sites/\(siteID)/exports/start" }
    var sitePurchasesEndpoint: String { return "sites/\(siteID)/purchases" }

    var remote: SiteManagementServiceRemote!

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()

        remote = SiteManagementServiceRemote(wordPressComRestApi: restApi)
    }

    override func tearDown() {
        super.tearDown()
        
        remote = nil
    }

    // MARK: - Delete Site Tests


    func testDeleteSiteSucceeds() {
        let expect = expectation(description: "Delete site success")

        stubRemoteResponse(siteDeleteEndpoint, filename: deleteSiteSuccessMockFilename, contentType: .ApplicationJSON)
        remote.deleteSite(NSNumber(value: Int32(siteID)), success: {
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteSiteWithServerErrorFails() {
        let expect = expectation(description: "Delete site server error failure")

        stubRemoteResponse(siteDeleteEndpoint, data: Data(), contentType: .NoContentType, status: 500)
        remote.deleteSite(NSNumber(value: Int32(siteID)), success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            guard let error = error as NSError? else {
                XCTFail("The returned error could not be cast as NSError")
                expect.fulfill()
                return
            }
            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiError.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteSiteWithBadAuthFails() {
        let expect = expectation(description: "Delete site with bad auth failure")

        stubRemoteResponse(siteDeleteEndpoint, filename: deleteSiteAuthFailureMockFilename, contentType: .ApplicationJSON, status: 403)
        remote.deleteSite(NSNumber(value: Int32(siteID)), success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            guard let error = error as NSError? else {
                XCTFail("The returned error could not be cast as NSError")
                expect.fulfill()
                return
            }
            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiError.authorizationRequired.rawValue, "The error code should be 2 - authorization_required")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteSiteWithBadJsonFails() {
        let expect = expectation(description: "Delete site with invalid json response failure")

        stubRemoteResponse(siteDeleteEndpoint, filename: deleteSiteBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.deleteSite(NSNumber(value: Int32(siteID)), success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteSiteWithUnexpectedJsonFails() {
        let expect = expectation(description: "Delete site with unexpected (valid) json response failure")

        stubRemoteResponse(siteDeleteEndpoint, filename: deleteSiteUnexpectedJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.deleteSite(NSNumber(value: Int32(siteID)), success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            guard let error = error as NSError? else {
                XCTFail("The returned error could not be cast as NSError")
                expect.fulfill()
                return
            }
            XCTAssertEqual(error.domain, String(reflecting: SiteManagementServiceRemote.SiteError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, SiteManagementServiceRemote.SiteError.deleteInvalidResponse._code, "The error code should be 0 - delete invalid response")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDeleteSiteWithMissingStatusFails() {
        let expect = expectation(description: "Delete site with missing status in json response failure")

        stubRemoteResponse(siteDeleteEndpoint, filename: deleteSiteMissingStatusJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.deleteSite(NSNumber(value: Int32(siteID)), success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            guard let error = error as NSError? else {
                XCTFail("The returned error could not be cast as NSError")
                expect.fulfill()
                return
            }
            XCTAssertEqual(error.domain, String(reflecting: SiteManagementServiceRemote.SiteError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, SiteManagementServiceRemote.SiteError.deleteMissingStatus._code, "The error code should be 1 - delete missing status")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: - Export Content Tests

    func testExportContentSucceeds() {
        let expect = expectation(description: "Export content success")

        stubRemoteResponse(siteExportStartEndpoint, filename: exportContentSuccessMockFilename, contentType: .ApplicationJSON)
        remote.exportContent(NSNumber(value: Int32(siteID)), success: {
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testExportContentWithNotRunningStatusInResponseFails() {
        let expect = expectation(description: "Export content with not-running status in response failure")

        stubRemoteResponse(siteExportStartEndpoint, filename: exportContentFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.exportContent(NSNumber(value: Int32(siteID)), success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            guard let error = error as NSError? else {
                XCTFail("The returned error could not be cast as NSError")
                expect.fulfill()
                return
            }
            XCTAssertEqual(error.domain, String(reflecting: SiteManagementServiceRemote.SiteError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, SiteManagementServiceRemote.SiteError.exportFailed._code, "The error code should be 5 - export failed status")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testExportContentWithServerErrorFails() {
        let expect = expectation(description: "Export content server error failure")

        stubRemoteResponse(siteExportStartEndpoint, data: Data(), contentType: .NoContentType, status: 500)
        remote.exportContent(NSNumber(value: Int32(siteID)), success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            guard let error = error as NSError? else {
                XCTFail("The returned error could not be cast as NSError")
                expect.fulfill()
                return
            }
            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiError.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testExportContentWithBadAuthFails() {
        let expect = expectation(description: "Export content with bad auth (or wrong site) failure")

        stubRemoteResponse(siteExportStartEndpoint, filename: exportContentAuthFailureMockFilename, contentType: .ApplicationJSON, status: 403)
        remote.exportContent(NSNumber(value: Int32(siteID)), success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            guard let error = error as NSError? else {
                XCTFail("The returned error could not be cast as NSError")
                expect.fulfill()
                return
            }
            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiError.authorizationRequired.rawValue, "The error code should be 2 - authorization_required")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testExportContentWithBadJsonFails() {
        let expect = expectation(description: "Export content with invalid json response failure")

        stubRemoteResponse(siteExportStartEndpoint, filename: exportContentBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.exportContent(NSNumber(value: Int32(siteID)), success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testExportContentWithUnexpectedJsonFails() {
        let expect = expectation(description: "Export content with unexpected (valid) json response failure")

        stubRemoteResponse(siteExportStartEndpoint, filename: deleteSiteUnexpectedJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.exportContent(NSNumber(value: Int32(siteID)), success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            guard let error = error as NSError? else {
                XCTFail("The returned error could not be cast as NSError")
                expect.fulfill()
                return
            }
            XCTAssertEqual(error.domain, String(reflecting: SiteManagementServiceRemote.SiteError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, SiteManagementServiceRemote.SiteError.exportInvalidResponse._code, "The error code should be 3 - export invalid response")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testExportContentWithMissingStatusFails() {
        let expect = expectation(description: "Export content with missing status in json response failure")

        stubRemoteResponse(siteExportStartEndpoint, filename: exportContentMissingStatusJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.exportContent(NSNumber(value: Int32(siteID)), success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            guard let error = error as NSError? else {
                XCTFail("The returned error could not be cast as NSError")
                expect.fulfill()
                return
            }
            XCTAssertEqual(error.domain, String(reflecting: SiteManagementServiceRemote.SiteError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, SiteManagementServiceRemote.SiteError.exportMissingStatus._code, "The error code should be 4 - export missing status")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: - Get Active Purchases Tests

    func testGetActivePurchasesSucceeds() {
        let expect = expectation(description: "Get active purchases success")

        stubRemoteResponse(sitePurchasesEndpoint, filename: getActivePurchasesSuccessMockFilename, contentType: .ApplicationJSON)
        remote.getActivePurchases(NSNumber(value: Int32(siteID)), success: { purchases in
            XCTAssertEqual(purchases.count, 2, "There should be 2 purchases here")
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetActivePurchasesWithNoActivesInResponseArraySucceeds() {
        let expect = expectation(description: "Get active purchases with no active purchases in response success")

        stubRemoteResponse(sitePurchasesEndpoint, filename: getActivePurchasesWithNoneActiveMockFilename, contentType: .ApplicationJSON)
        remote.getActivePurchases(NSNumber(value: Int32(siteID)), success: { purchases in
            XCTAssertEqual(purchases.count, 0, "There should be 0 purchases here")
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetActivePurchasesWithEmptyResponseArraySucceeds() {
        let expect = expectation(description: "Get active purchases with empty response success")

        stubRemoteResponse(sitePurchasesEndpoint, filename: getActivePurchasesWithEmptyResponseMockFilename, contentType: .ApplicationJSON)
        remote.getActivePurchases(NSNumber(value: Int32(siteID)), success: { purchases in
            XCTAssertEqual(purchases.count, 0, "There should be 0 purchases here")
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetActivePurchasesWithServerErrorFails() {
        let expect = expectation(description: "Get active purchases server error failure")

        stubRemoteResponse(sitePurchasesEndpoint, data: Data(), contentType: .NoContentType, status: 500)
        remote.getActivePurchases(NSNumber(value: Int32(siteID)), success: { purchases in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            guard let error = error as NSError? else {
                XCTFail("The returned error could not be cast as NSError")
                expect.fulfill()
                return
            }
            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiError.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetActivePurchasesWithBadAuthFails() {
        let expect = expectation(description: "Get active purchases with bad auth failure")

        stubRemoteResponse(sitePurchasesEndpoint, filename: getActivePurchasesAuthFailureMockFilename, contentType: .ApplicationJSON, status: 403)
        remote.getActivePurchases(NSNumber(value: Int32(siteID)), success: { purchases in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            guard let error = error as NSError? else {
                XCTFail("The returned error could not be cast as NSError")
                expect.fulfill()
                return
            }
            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiError.authorizationRequired.rawValue, "The error code should be 2 - authorization_required")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetActivePurchasesWithBadJsonFails() {
        let expect = expectation(description: "Get active purchases with invalid json response failure")

        stubRemoteResponse(sitePurchasesEndpoint, filename: getActivePurchasesBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.getActivePurchases(NSNumber(value: Int32(siteID)), success: { purchases in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetActivePurchasesWithUnexpectedJsonFails() {
        let expect = expectation(description: "Get active purchases with unexpected (valid) json response failure")

        stubRemoteResponse(sitePurchasesEndpoint, filename: deleteSiteUnexpectedJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.getActivePurchases(NSNumber(value: Int32(siteID)), success: { purchases in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            guard let error = error as NSError? else {
                XCTFail("The returned error could not be cast as NSError")
                expect.fulfill()
                return
            }
            XCTAssertEqual(error.domain, String(reflecting: SiteManagementServiceRemote.SiteError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, SiteManagementServiceRemote.SiteError.purchasesInvalidResponse._code, "The error code should be 6 - purchases invalid response")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: - Misc Tests

    func testSiteManagementErrorConversion() {
        let errors: [SiteManagementServiceRemote.SiteError] = [.deleteInvalidResponse, .deleteMissingStatus, .deleteFailed, .exportInvalidResponse, .exportMissingStatus, .exportFailed, .purchasesInvalidResponse]
        for error in errors {
            XCTAssertEqual(error.toNSError().localizedDescription, error.description, "Incorrect description provided")
        }
    }
}

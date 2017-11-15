import Foundation
import XCTest
@testable import WordPressKit

class ActivityServiceRemoteTests: RemoteTestCase, RESTTestable {

    /// MARK: - Constants

    let siteID = 321
    let rewindID = "33"
    let restoreID = "22"

    let getActivitySuccessOneMockFilename = "activity-log-success-1.json"
    let getActivitySuccessTwoMockFilename = "activity-log-success-2.json"
    let getActivitySuccessThreeMockFilename = "activity-log-success-3.json"
    let getActivityBadJsonFailureMockFilename = "activity-log-bad-json-failure.json"
    let getActivityAuthFailureMockFilename = "activity-log-auth-failure.json"
    let restoreSuccessMockFilename = "activity-restore-success.json"
    let restoreBadIdFailureMockFilename = "activity-restore-bad-id-failure.json"
    let restoreStatusSuccessMockFilename = "activity-restore-status-success.json"
    let restoreStatusFailureMockFilename = "activity-restore-status-failure.json"

    /// MARK: - Properties

    var siteActivityEndpoint: String { return "sites/\(siteID)/activity" }
    var restoreEndpoint: String { return "activity-log/\(siteID)/rewind/to/\(rewindID)" }
    var restoreStatusEndpoint: String { return "activity-log/\(siteID)/rewind/\(restoreID)/restore-status" }

    var remote: ActivityServiceRemote!

    /// MARK: - Overridden Methods

    override func setUp() {
        super.setUp()

        remote = ActivityServiceRemote(wordPressComRestApi: getRestApi())
    }

    override func tearDown() {
        super.tearDown()

        remote = nil
    }

    /// MARK: - Get Activity Tests

    func testGetActivitySucceedsOne() {
        let expect = expectation(description: "Get activity for site success one")

        stubRemoteResponse(siteActivityEndpoint, filename: getActivitySuccessOneMockFilename, contentType: .ApplicationJSON)
        remote.getActivityForSite(siteID,
                                  offset: 0,
                                  count: 20,
                                  success: { (activities, hasMore) in
                                      XCTAssertEqual(activities.count, 8, "The activity count should be 8")
                                      XCTAssertEqual(hasMore, false, "The value of hasMore should be false")
                                      expect.fulfill()
                                  }, failure: { error in
                                      XCTFail("This callback shouldn't get called")
                                      expect.fulfill()
                                  })
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetActivitySucceedsTwo() {
        let expect = expectation(description: "Get activity for site success two")

        stubRemoteResponse(siteActivityEndpoint, filename: getActivitySuccessTwoMockFilename, contentType: .ApplicationJSON)
        remote.getActivityForSite(siteID,
                                  offset: 0,
                                  count: 20,
                                  success: { (activities, hasMore) in
                                      XCTAssertEqual(activities.count, 20, "The activity count should be 20")
                                      XCTAssertEqual(hasMore, true, "The value of hasMore should be true")
                                      expect.fulfill()
                                  }, failure: { error in
                                      XCTFail("This callback shouldn't get called")
                                      expect.fulfill()
                                  })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetActivitySucceedsThree() {
        let expect = expectation(description: "Get activity for site success three")

        stubRemoteResponse(siteActivityEndpoint, filename: getActivitySuccessThreeMockFilename, contentType: .ApplicationJSON)
        remote.getActivityForSite(siteID,
                                  offset: 100,
                                  count: 20,
                                  success: { (activities, hasMore) in
                                      XCTAssertEqual(activities.count, 19, "The activity count should be 19")
                                      XCTAssertEqual(hasMore, false, "The value of hasMore should be false")
                                      expect.fulfill()
                                  }, failure: { error in
                                      XCTFail("This callback shouldn't get called")
                                      expect.fulfill()
                                  })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetActivityWithBadAuthFails() {
        let expect = expectation(description: "Get activity with bad auth failure")

        stubRemoteResponse(siteActivityEndpoint, filename: getActivityAuthFailureMockFilename, contentType: .ApplicationJSON, status: 403)
        remote.getActivityForSite(siteID,
                                  count: 20,
                                  success: { (activities, hasMore) in
                                      XCTFail("This callback shouldn't get called")
                                      expect.fulfill()
                                  }, failure: { error in
                                      let error = error as NSError
                                      XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
                                      XCTAssertEqual(error.code, WordPressComRestApiError.authorizationRequired.rawValue, "The error code should be 2 - authorization_required")
                                      expect.fulfill()
                                  })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetActivityWithBadJsonFails() {
        let expect = expectation(description: "Get activity with invalid json response failure")

        stubRemoteResponse(siteActivityEndpoint, filename: getActivityBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.getActivityForSite(siteID,
                                  count: 20,
                                  success: { (activities, hasMore) in
                                      XCTFail("This callback shouldn't get called")
                                      expect.fulfill()
                                 }, failure: { error in
                                      expect.fulfill()
                                 })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testRestoreSucceeds() {
        let expect = expectation(description: "Trigger restore success")

        stubRemoteResponse(restoreEndpoint, filename: restoreSuccessMockFilename, contentType: .ApplicationJSON)

        remote.restoreSite(siteID,
                           rewindID: rewindID,
                           success: { (restoreID) in
                               XCTAssertEqual(restoreID, self.restoreID)
                               expect.fulfill()
                           }, failure: { error in
                               XCTFail("This callback shouldn't get called")
                               expect.fulfill()
                           })
        waitForExpectations(timeout: timeout, handler: nil)
    }

    // This test is commented because the server is not returning an error upon an invalid rewindId.
    // Once that starts happening we will update the mock file accordingly and enable this test.
    /*func testRestoreWithBadIdFails() {
        let expect = expectation(description: "Trigger restore success")

        stubRemoteResponse(restoreEndpoint, filename: restoreSuccessMockFilename, contentType: .ApplicationJSON)

        remote.restoreSite(siteID,
                           rewindID: rewindID,
                           success: { (restoreID) in
                               XCTFail("This callback shouldn't get called")
                               expect.fulfill()
                           }, failure: { error in
                               expect.fulfill()
                           })
        waitForExpectations(timeout: timeout, handler: nil)
    }*/

    func testGetRestoreStatusSuceeds() {
        let expect = expectation(description: "Check restore status success")

        stubRemoteResponse(restoreStatusEndpoint, filename: restoreStatusSuccessMockFilename, contentType: .ApplicationJSON)

        remote.restoreStatusForSite(siteID,
                                    restoreID: restoreID,
                                    success: { (restoreStatus) in
                                        XCTAssertEqual(restoreStatus.status, .finished)
                                        XCTAssertEqual(restoreStatus.percent, 100)
                                        expect.fulfill()
                                    }, failure: { error in
                                        XCTFail("This callback shouldn't get called")
                                        expect.fulfill()
                                    })
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetRestoreStatusWithBadJsonFails() {
        let expect = expectation(description: "Check restore status failure")

        stubRemoteResponse(restoreStatusEndpoint, filename: restoreStatusFailureMockFilename, contentType: .ApplicationJSON)

        remote.restoreStatusForSite(siteID,
                                    restoreID: restoreID,
                                    success: { (restoreStatus) in
                                        XCTFail("This callback shouldn't get called")
                                        expect.fulfill()
                                    }, failure: { error in
                                        expect.fulfill()
                                    })
        waitForExpectations(timeout: timeout, handler: nil)
    }
}


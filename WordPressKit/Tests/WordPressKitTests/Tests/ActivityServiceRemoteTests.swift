import Foundation
import OHHTTPStubs
import XCTest
@testable import WordPressKit

class ActivityServiceRemoteTests: RemoteTestCase, RESTTestable {

    // MARK: - Constants

    let siteID = 321
    let rewindID = "33"
    let restoreID = "22"
    let jobID = 1444315452

    let getActivitySuccessOneMockFilename = "activity-log-success-1.json"
    let getActivitySuccessTwoMockFilename = "activity-log-success-2.json"
    let getActivitySuccessThreeMockFilename = "activity-log-success-3.json"
    let getActivityBadJsonFailureMockFilename = "activity-log-bad-json-failure.json"
    let getActivityAuthFailureMockFilename = "activity-log-auth-failure.json"
    let getActivityGroupsSuccessMockFilename = "activity-groups-success.json"
    let getActivityGroupsBadJsonFailureMockFilename = "activity-groups-bad-json-failure.json"
    let restoreSuccessMockFilename = "activity-restore-success.json"
    let rewindStatusSuccessMockFilename = "activity-rewind-status-success.json"
    let rewindStatusRestoreFailureMockFilename = "activity-rewind-status-restore-failure.json"
    let rewindStatusRestoreFinishedMockFilename = "activity-rewind-status-restore-finished.json"
    let rewindStatusRestoreInProgressMockFilename = "activity-rewind-status-restore-in-progress.json"
    let rewindStatusRestoreQueuedMockFilename = "activity-rewind-status-restore-queued.json"

    // MARK: - Properties

    var siteActivityEndpoint: String { return "sites/\(siteID)/activity" }
    var siteActivityGroupsEndpoint: String { return "sites/\(siteID)/activity/count/group" }
    var restoreEndpoint: String { return "activity-log/\(siteID)/rewind/to/\(rewindID)" }
    var rewindStatusEndpoint: String { return "sites/\(siteID)/rewind" }

    var remoteV1: ActivityServiceRemote_ApiVersion1_0!
    var remote: ActivityServiceRemote!

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()

        remoteV1 = ActivityServiceRemote_ApiVersion1_0(wordPressComRestApi: getRestApi())

        let v2RestApi = WordPressComRestApi(localeKey: WordPressComRestApi.LocaleKeyV2)
        remote = ActivityServiceRemote(wordPressComRestApi: v2RestApi)

        NSTimeZone.default = NSTimeZone(forSecondsFromGMT: 0) as TimeZone
    }

    override func tearDown() {
        super.tearDown()

        remote = nil

        NSTimeZone.default = NSTimeZone.local
    }

    // MARK: - Get Activity Tests

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
                                  }, failure: { _ in
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
                                  }, failure: { _ in
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
                                  }, failure: { _ in
                                      XCTFail("This callback shouldn't get called")
                                      expect.fulfill()
                                  })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetActivityWithParameters() {
        let expect = expectation(description: "Get activity for site success when calling with after, before, and group")
        let dateFormatter = ISO8601DateFormatter()

        stubRemoteResponse("group%5B%5D=post&group%5B%5D=user&number=20&page=6&after=1970-01-01%2010:44:00&before=1970-01-03%2010:43:59", filename: getActivitySuccessThreeMockFilename, contentType: .ApplicationJSON)
        remote.getActivityForSite(siteID,
                                  offset: 100,
                                  count: 20,
                                  after: dateFormatter.date(from: "1970-01-01T10:44:00+0000"),
                                  before: dateFormatter.date(from: "1970-01-02T10:44:00+0000"),
                                  group: ["post", "user"],
                                  success: { (activities, hasMore) in
                                      XCTAssertEqual(activities.count, 19, "The activity count should be 19")
                                      XCTAssertEqual(hasMore, false, "The value of hasMore should be false")
                                      expect.fulfill()
                                  }, failure: { _ in
                                      XCTFail("This callback shouldn't get called")
                                      expect.fulfill()
                                  })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetActivityWithParametersWithOnlyAfter() {
        let expect = expectation(description: "Get activity for site success when calling with after")
        let dateFormatter = ISO8601DateFormatter()

        stubRemoteResponse("wpcom/v2/sites/321/activity?number=20&page=1&on=1970-01-01%2010:44:00", filename: getActivitySuccessThreeMockFilename, contentType: .ApplicationJSON)
        remote.getActivityForSite(siteID,
                                  count: 20,
                                  after: dateFormatter.date(from: "1970-01-01T10:44:00+0000"),
                                  success: { (_, _) in
                                      expect.fulfill()
                                  }, failure: { _ in
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
                                  success: { (_, _) in
                                      XCTFail("This callback shouldn't get called")
                                      expect.fulfill()
                                  }, failure: { error in
                                      let error = error as NSError
                                      XCTAssertEqual(error.domain, "WordPressKit.WordPressComRestApiError", "The error domain should be WordPressComRestApiError")
                                      XCTAssertEqual(error.code, WordPressComRestApiErrorCode.authorizationRequired.rawValue, "The error code should be 2 - authorization_required")
                                      expect.fulfill()
                                  })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetActivityWithBadJsonFails() {
        let expect = expectation(description: "Get activity with invalid json response failure")

        stubRemoteResponse(siteActivityEndpoint, filename: getActivityBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.getActivityForSite(siteID,
                                  count: 20,
                                  success: { (_, _) in
                                      XCTFail("This callback shouldn't get called")
                                      expect.fulfill()
                                 }, failure: { _ in
                                      expect.fulfill()
                                 })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetActivityGroupsSucceeds() {
        let expect = expectation(description: "Get activity groups success")

        stubRemoteResponse(siteActivityGroupsEndpoint, filename: getActivityGroupsSuccessMockFilename, contentType: .ApplicationJSON)
        remote.getActivityGroupsForSite(siteID,
                                        success: { groups in
                                            XCTAssertEqual(groups.count, 4, "The activity group count should be 4")
                                            XCTAssertTrue(groups.contains(where: { $0.key == "post" && $0.name == "Posts and Pages" && $0.count == 69}))
                                            XCTAssertTrue(groups.contains(where: { $0.key == "attachment" && $0.name == "Media" && $0.count == 5}))
                                            XCTAssertTrue(groups.contains(where: { $0.key == "user" && $0.name == "People" && $0.count == 2}))
                                            XCTAssertTrue(groups.contains(where: { $0.key == "rewind" && $0.name == "Backups and Restores" && $0.count == 10}))
                                            expect.fulfill()
                                        },
                                        failure: { _ in
                                            XCTFail("This callback shouldn't get called")
                                            expect.fulfill()
                                        })
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetActivityGroupsWithParameters() {
        let expect = expectation(description: "Get activity groups for site success when calling with before, after")
        let dateFormatter = ISO8601DateFormatter()

        stubRemoteResponse("1970-01-01%2010%3A44%3A00&before=1970-01-03%2010%3A43%3A59", filename: getActivityGroupsSuccessMockFilename, contentType: .ApplicationJSON)
        remote.getActivityGroupsForSite(siteID,
                                        after: dateFormatter.date(from: "1970-01-01T10:44:00+0000"),
                                        before: dateFormatter.date(from: "1970-01-02T10:44:00+0000"),
                                        success: { _ in
                                            expect.fulfill()
                                        },
                                        failure: { _ in
                                            XCTFail("This callback shouldn't get called")
                                            expect.fulfill()
                                        })
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetActivityGroupsWithParametersWithOnlyAfter() {
        let expect = expectation(description: "Get activity groups for site success when calling with after")
        let dateFormatter = ISO8601DateFormatter()

        stubRemoteResponse("on=1970-01-01", filename: getActivityGroupsSuccessMockFilename, contentType: .ApplicationJSON)
        remote.getActivityGroupsForSite(siteID,
                                        before: dateFormatter.date(from: "1970-01-01T10:44:00+0000"),
                                        success: { groups in
                                            XCTAssertEqual(groups.count, 4, "The activity count should be 4")
                                            expect.fulfill()
                                        }, failure: { _ in
                                            XCTFail("This callback shouldn't get called")
                                            expect.fulfill()
                                        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetActivityGroupsWithBadJsonFails() {
        let expect = expectation(description: "Get activity groups with invalid json response failure")

        stubRemoteResponse(siteActivityGroupsEndpoint, filename: getActivityGroupsBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.getActivityGroupsForSite(siteID,
                                  success: { _ in
                                      XCTFail("This callback shouldn't get called")
                                      expect.fulfill()
                                 }, failure: { _ in
                                      expect.fulfill()
                                 })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testRestoreSucceeds() {
        let expect = expectation(description: "Trigger restore success")

        stubRemoteResponse(restoreEndpoint, filename: restoreSuccessMockFilename, contentType: .ApplicationJSON)

        remoteV1.restoreSite(siteID,
                             rewindID: rewindID,
                             success: { (restoreID, jobID) in
                                XCTAssertEqual(restoreID, self.restoreID)
                                XCTAssertEqual(jobID, self.jobID)
                                expect.fulfill()
                             }, failure: { _ in
                                XCTFail("This callback shouldn't get called")
                                expect.fulfill()
                             })
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testRestoreSucceedsWithParameters() {
        let expect = expectation(description: "Trigger restore success")

        stubRemoteResponse(restoreEndpoint, filename: restoreSuccessMockFilename, contentType: .ApplicationJSON)

        let restoreTypes = JetpackRestoreTypes(themes: true,
                                               plugins: true,
                                               uploads: true,
                                               sqls: true,
                                               roots: true,
                                               contents: true)

        remoteV1.restoreSite(siteID,
                             rewindID: rewindID,
                             types: restoreTypes,
                             success: { (restoreID, jobID) in
                                XCTAssertEqual(restoreID, self.restoreID)
                                XCTAssertEqual(jobID, self.jobID)
                                expect.fulfill()
                             }, failure: { _ in
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

    func testGetRewindStatusSuccess() {
        let expect = expectation(description: "Check rewind status success")

        stubRemoteResponse(rewindStatusEndpoint, filename: rewindStatusSuccessMockFilename, contentType: .ApplicationJSON)

        remote.getRewindStatus(siteID,
                               success: { (rewindStatus) in
                                   XCTAssertEqual(rewindStatus.state, .active)
                                   XCTAssertNotNil(rewindStatus.lastUpdated)
                                   XCTAssertNil(rewindStatus.restore)
                                   expect.fulfill()
                               }, failure: { _ in
                                    XCTFail("This callback shouldn't get called")
                                    expect.fulfill()
                               })
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetRewindStatusRestoreFinish() {
        let expect = expectation(description: "Check rewind status, restore finished")

        stubRemoteResponse(rewindStatusEndpoint, filename: rewindStatusRestoreFinishedMockFilename, contentType: .ApplicationJSON)

        remote.getRewindStatus(siteID,
                               success: { (rewindStatus) in
                                   XCTAssertNotNil(rewindStatus.restore)
                                   XCTAssertNotNil(rewindStatus.restore!.id)
                                   XCTAssertEqual(rewindStatus.restore!.status, .finished)
                                   XCTAssertEqual(rewindStatus.restore!.progress, 100)
                                   XCTAssertNil(rewindStatus.restore!.failureReason)
                                   expect.fulfill()
                                }, failure: { _ in
                                   XCTFail("This callback shouldn't get called")
                                   expect.fulfill()
                                })
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetRewindStatusRestoreFailure() {
        let expect = expectation(description: "Check rewind status, restore failure")

        stubRemoteResponse(rewindStatusEndpoint, filename: rewindStatusRestoreFailureMockFilename, contentType: .ApplicationJSON)

        remote.getRewindStatus(siteID,
                               success: { (rewindStatus) in
                                   XCTAssertNotNil(rewindStatus.restore)
                                   XCTAssertNotNil(rewindStatus.restore!.id)
                                   XCTAssertEqual(rewindStatus.restore!.status, .fail)
                                   XCTAssertEqual(rewindStatus.restore!.progress, 0)
                                   XCTAssertNotNil(rewindStatus.restore!.failureReason)
                                   XCTAssert(rewindStatus.restore!.failureReason!.count > 0)
                                   expect.fulfill()
                                }, failure: { _ in
                                   expect.fulfill()
                                })
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetRewindStatusRestoreInProgress() {
        let expect = expectation(description: "Check rewind status, restore in progress")

        stubRemoteResponse(rewindStatusEndpoint, filename: rewindStatusRestoreInProgressMockFilename, contentType: .ApplicationJSON)

        remote.getRewindStatus(siteID,
                               success: { (rewindStatus) in
                                   XCTAssertNotNil(rewindStatus.restore)
                                   XCTAssertNotNil(rewindStatus.restore!.id)
                                   XCTAssertEqual(rewindStatus.restore!.status, .running)
                                   XCTAssert(rewindStatus.restore!.progress > 0)
                                   XCTAssertNil(rewindStatus.restore!.failureReason)
                                   expect.fulfill()
                               }, failure: { _ in
                                   expect.fulfill()
                               })
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetRestoreStatusRestoreQueued() {
        let expect = expectation(description: "Check rewind status, restore queued")

        stubRemoteResponse(rewindStatusEndpoint, filename: rewindStatusRestoreQueuedMockFilename, contentType: .ApplicationJSON)

        remote.getRewindStatus(siteID,
                               success: { (rewindStatus) in
                                   XCTAssertNotNil(rewindStatus.restore)
                                   XCTAssertNotNil(rewindStatus.restore!.id)
                                   XCTAssertEqual(rewindStatus.restore!.status, .queued)
                                   XCTAssertEqual(rewindStatus.restore!.progress, 0)
                                   XCTAssertNil(rewindStatus.restore!.failureReason)
                                   expect.fulfill()
                               }, failure: { _ in
                                   expect.fulfill()
                               })
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testNotConnectedToJetpack() {
        let expect = expectation(description: "Check rewind status")

        stub(condition: { $0.url?.path.contains(self.rewindStatusEndpoint) ?? false }) { _ in
            HTTPStubsResponse(jsonObject: ["code": "no_connected_jetpack"], statusCode: 412, headers: nil)
        }

        remote.getRewindStatus(siteID) {
            expect.fulfill()
            XCTAssertEqual($0.state, .unavailable)
        } failure: { error in
            expect.fulfill()
            XCTFail("The success block should be called")
        }

        wait(for: [expect], timeout: 0.3)
    }
}

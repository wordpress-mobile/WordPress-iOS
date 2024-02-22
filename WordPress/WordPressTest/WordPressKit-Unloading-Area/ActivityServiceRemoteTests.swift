import Foundation
import OHHTTPStubs
import XCTest
@testable import WordPress

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

//
// Duplicated from WordPressKit
//
import BuildkiteTestCollector

/// Base class for all remote unit tests.
///
class RemoteTestCase: XCTestCase {

    /// Response content types
    ///
    enum ResponseContentType: String {
        case ApplicationJSON = "application/json"
        case JavaScript      = "text/javascript;charset=utf-8"
        case ApplicationHTML = "application/html"
        case XML             = "text/xml"
        case NoContentType   = ""
    }

    // MARK: - Constants

    let timeout = TimeInterval(5)

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        stubAllNetworkRequestsWithNotConnectedError()
    }

    override func tearDown() {
        super.tearDown()

        HTTPStubs.removeAllStubs()
    }
}

// MARK: - Remote testing helpers
//
extension RemoteTestCase {

    /// Helper function that creates a stub which uses a file for the response body.
    ///
    /// - Parameters:
    ///     - condition: The endpoint matcher block that determines if the request will be stubbed
    ///     - filename: The name of the file to use for the response
    ///     - contentType: The Content-Type returned in the response header
    ///     - status: The status code to use for the response. Defaults to 200.
    ///
    func stubRemoteResponse(
        _ condition: @escaping (URLRequest) -> Bool,
        filename: String,
        contentType: ResponseContentType,
        status: Int32 = 200
    ) {
        stub(condition: condition) { _ in
            guard let stubPath = OHPathForFile(filename, type(of: self)) else {
                fatalError("Could not find stub file named '\(filename)' in module for type \(type(of: self))'.")
            }

            var headers: [NSObject: AnyObject]?

            if contentType != .NoContentType {
                headers = ["Content-Type" as NSObject: contentType.rawValue as AnyObject]
            }
            return OHHTTPStubs.fixture(filePath: stubPath, status: status, headers: headers)
        }
    }

    /// Helper function that creates a stub which uses a file for the response body.
    ///
    /// - Parameters:
    ///     - endpoint: The endpoint matcher block that determines if the request will be stubbed
    ///     - filename: The name of the file to use for the response
    ///     - contentType: The Content-Type returned in the response header
    ///     - status: The status code to use for the response. Defaults to 200.
    ///
    func stubRemoteResponse(_ endpoint: String, filename: String, contentType: ResponseContentType, status: Int32 = 200) {
        stub(condition: { request in
            return request.url?.absoluteString.range(of: endpoint) != nil
        }) { _ in
            guard let stubPath = OHPathForFile(filename, type(of: self)) else {
                fatalError("Could not find stub file named '\(filename)' in module for type \(type(of: self))'.")
            }

            var headers: [NSObject: AnyObject]?

            if contentType != .NoContentType {
                headers = ["Content-Type" as NSObject: contentType.rawValue as AnyObject]
            }
            return fixture(filePath: stubPath, status: status, headers: headers)
        }
    }

    /// Helper function that creates a stub which uses the provided Data object for the response body.
    ///
    /// - Parameters:
    ///     - endpoint: The endpoint matcher block that determines if the request will be stubbed
    ///     - data: Data object to use for the response
    ///     - contentType: The Content-Type returned in the response header
    ///     - status: The status code to use for the response. Defaults to 200.
    ///
    func stubRemoteResponse(_ endpoint: String, data: Data, contentType: ResponseContentType, status: Int32 = 200) {
        stub(condition: { request in
            return request.url?.absoluteString.range(of: endpoint) != nil
        }) { _ in
            var headers: [NSObject: AnyObject]?

            if contentType != .NoContentType {
                headers = ["Content-Type" as NSObject: contentType.rawValue as AnyObject]
            }
            return HTTPStubsResponse(data: data, statusCode: status, headers: headers)
        }
    }

    /// Helper function that creates a stub which uses an array of files for the response body. Files
    /// are returned sequentially for each subsequent call to the stubbed endpoint. Example: if an array
    /// of [File1, File2] is passed in, then call number #1 to the stub will return File1 and
    /// call #2 to the stub will return File2.
    ///
    /// - Note: This function can be useful when testing XMLRPC because the same endpoint is used for multiple
    ///         methods.
    ///
    /// - Parameters:
    ///     - endpoint: The endpoint matcher block that determines if the request will be stubbed
    ///     - files: An array of files to use for the responses
    ///     - contentType: The Content-Type returned in the response header
    ///     - status: The status code to use for the response. Defaults to 200.
    ///
    func stubRemoteResponse(_ endpoint: String, files: [String], contentType: ResponseContentType, status: Int32 = 200) {
        var callCounter = 0
        stub(condition: { request in
            return request.url?.absoluteString.range(of: endpoint) != nil
        }) { response in
            guard files.indices.contains(callCounter) else {
                // An extra call was made to this stub and no corresponding response file existed.
                XCTFail("Unexpected network request was made to: \(response.url!.absoluteString)")
                let notConnectedError = NSError(domain: NSURLErrorDomain, code: Int(CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue), userInfo: nil)
                return HTTPStubsResponse(error: notConnectedError)
            }

            let stubPath = OHPathForFile(files[callCounter], type(of: self))
            callCounter += 1

            var headers: [NSObject: AnyObject]?
            if contentType != .NoContentType {
                headers = ["Content-Type" as NSObject: contentType.rawValue as AnyObject]
            }

            return fixture(filePath: stubPath!, status: status, headers: headers)
        }
    }

    /// Helper function that stubs ALL endpoints so that they return a CFNetworkErrors.cfurlErrorNotConnectedToInternet
    /// error. In the response, prior to returning the error, XCTFail will also be called logging the endpoint
    /// which was called.
    ///
    /// - Note: Remember that order is important when stubbing requests with HTTPStubs. Therefore, it is important
    ///         this is called **before** stubbing out a specific endpoint you are testing. See:
    ///         https://github.com/AliSoftware/OHHTTPStubs/wiki/Usage-Examples#stack-multiple-stubs-and-remove-installed-stubs
    ///
    func stubAllNetworkRequestsWithNotConnectedError() {
        // Stub all requests other than those to the Buildkite Test Analytics API,
        // which we need them to go through for Test Analytics reporting.
        stub(condition: !isHost(TestCollector.apiHost)) { response in
            XCTFail("Unexpected network request was made to: \(response.url!.absoluteString)")
            let notConnectedError = NSError(domain: NSURLErrorDomain, code: Int(CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue), userInfo: nil)
            return HTTPStubsResponse(error: notConnectedError)
        }
    }

    /// Helper function that clears any *.json files from the local disk cache. Useful for ensuring a network
    /// call is made instead of a cache hit.
    ///
    func clearDiskCache() {
        let cacheDirectory =  FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first! as NSURL

        do {
            if let documentPath = cacheDirectory.path {
                let fileNames = try FileManager.default.contentsOfDirectory(atPath: "\(documentPath)")
                for fileName in fileNames {
                    if fileName.hasSuffix(".json") {
                        print("Removing \(fileName) from cache.")
                        let filePathName = "\(documentPath)/\(fileName)"
                        try FileManager.default.removeItem(atPath: filePathName)
                    }
                }
            }
        } catch {
            print("Unable to clear cache: \(error)")
        }
    }

    /// Checks if the specified set of query parameter names are all present in a given `URLRequest`.
    /// This method verifies the presence of query parameter names in the request's URL without evaluating their values.
    ///
    /// - Parameters:
    ///   - queryParams: A set of query parameter names to check for in the request.
    ///   - request: The `URLRequest` to inspect for the presence of query parameter names.
    /// - Returns: A Boolean value indicating whether all specified query parameter names are present in the request's URL.
    func queryParams(_ queryParams: Set<String>, containedInRequest request: URLRequest) -> Bool {
        guard let url = request.url else {
            return false
        }
        return self.queryParams(queryParams, containedInURL: url)
    }

    /// Checks if the specified set of query parameter names are all present in a given `URL`.
    /// This method verifies the presence of query parameter names in the URL's query string without evaluating their values.
    ///
    /// - Parameters:
    ///   - queryParams: A set of query parameter names to check for in the URL.
    ///   - url: The `URL` to inspect for the presence of query parameter names.
    /// - Returns: A Boolean value indicating whether all specified query parameter names are present in the URL's query string.
    func queryParams(_ queryParams: Set<String>, containedInURL url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems?.map({ $0.name })
        else {
            return false
        }
        return queryParams.intersection(queryItems) == queryParams
    }
}

/// Protocol to be used when testing REST Remotes
///
protocol RESTTestable {
    func getRestApi() -> WordPressComRestApi
}

extension RESTTestable {
    func getRestApi() -> WordPressComRestApi {
        return WordPressComRestApi(oAuthToken: nil, userAgent: nil)
    }
}

// This now be part of the library
extension TestCollector {

    static let apiHost = "analytics-api.buildkite.com"
}

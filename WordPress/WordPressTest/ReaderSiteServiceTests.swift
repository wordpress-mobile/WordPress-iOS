import Nimble
import OHHTTPStubs
@testable import WordPress
import WordPressKit
import XCTest

class ReaderSiteServiceTests: CoreDataTestCase {

    override class func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testFollowSiteByURL() {
        stub(condition: isHost("test.blog")) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }
        stub(condition: isPath("/rest/v1.1/sites/test.blog")) { _ in
            HTTPStubsResponse(jsonObject: ["ID": 42], statusCode: 200, headers: nil)
        }
        stub(condition: isPath("/rest/v1.1/sites/42/follows/mine")) { _ in
            HTTPStubsResponse(jsonObject: ["is_following": false], statusCode: 200, headers: nil)
        }
        stub(condition: isPath("/rest/v1.1/sites/42/follows/new")) { _ in
            HTTPStubsResponse(jsonObject: [String: Any](), statusCode: 200, headers: nil)
        }
        stub(condition: isPath("/rest/v1.2/read/sites/42")) { _ in
            HTTPStubsResponse(jsonObject: [
                "feed_ID": 100,
                "feed_URL": "https://test.blog/feed",
                "post_count": 0,
            ] as [String: Any], statusCode: 200, headers: nil)
        }

        let service = makeService()
        let success = expectation(description: "The success block should be called")
        service.followSite(by: URL(string: "https://test.blog")!, success: success.fulfill, failure: nil)
        wait(for: [success], timeout: 0.5)
    }

    func testFollowSiteByID() {
        stub(condition: isPath("/rest/v1.1/sites/42/follows/mine")) { _ in
            HTTPStubsResponse(jsonObject: ["is_following": false], statusCode: 200, headers: nil)
        }
        stub(condition: isPath("/rest/v1.1/sites/42/follows/new")) { _ in
            HTTPStubsResponse(jsonObject: [String: Any](), statusCode: 200, headers: nil)
        }
        stub(condition: isPath("/rest/v1.2/read/sites/42")) { _ in
            HTTPStubsResponse(jsonObject: [
                "feed_ID": 100,
                "feed_URL": "https://test.blog/feed",
                "post_count": 0,
            ] as [String: Any], statusCode: 200, headers: nil)
        }

        let service = makeService()
        let success = expectation(description: "The success block should be called")
        service.followSite(withID: 42, success: success.fulfill, failure: nil)
        wait(for: [success], timeout: 0.5)
    }

    func testUnfollowSiteByID() {
        stub(condition: isPath("/rest/v1.1/sites/42/follows/mine/delete")) { _ in
            HTTPStubsResponse(jsonObject: [String: Any](), statusCode: 200, headers: nil)
        }

        let service = makeService()
        let success = expectation(description: "The success block should be called")
        service.unfollowSite(withID: 42, success: success.fulfill, failure: nil)
        wait(for: [success], timeout: 0.5)
    }

    func testFlagAsBlockedSuccessPath() {
        let service = makeService()
        let siteID: NSNumber = 42

        stub(condition: isPath("/rest/v1.1/me/block/sites/\(siteID)/new")) { _ in
            HTTPStubsResponse(jsonObject: ["success": 1], statusCode: 200, headers: nil)
        }

        waitUntil { done in
            service.flagSite(
                withID: siteID,
                asBlocked: true,
                success: {
                    done()
                },
                failure: { error in
                    // We call done in this failure scenario because we explicitly fail afterwards.
                    // Without this call, the test would have two failures:
                    // one because done was not called (timeout) and the explicit fail with error
                    done()
                    fail("Expected call to succeed. Failed with \(error?.localizedDescription ?? "'nil-error'")")
                }
            )
        }
    }

    func testFlagAsBlockedFailurePath() {
        let service = makeService()
        let siteID: NSNumber = 42

        stub(condition: isPath("/rest/v1.1/me/block/sites/\(siteID)/new")) { _ in
            HTTPStubsResponse(jsonObject: ["success": 0], statusCode: 200, headers: nil)
        }

        waitUntil { done in
            service.flagSite(
                withID: siteID,
                asBlocked: true,
                success: {
                    // We call done in this failure scenario because we explicitly fail afterwards.
                    // Without this call, the test would have two failures:
                    // one because done was not called (timeout) and the explicit fail with error
                    done()
                    fail("Expected call to fail, but succeeded")
                },
                failure: { error in
                    expect((error as? NSError)?.domain) == ReaderSiteServiceRemoteErrorDomain
                    expect((error as? NSError)?.code) == Int(ReaderSiteServiceRemoteError.sErviceRemoteUnsuccessfulBlockSite.rawValue)
                    done()
                }
            )
        }
    }

    func testFlagAsUnblockedSuccessPath() {
        let service = makeService()
        let siteID: NSNumber = 42

        stub(condition: isPath("/rest/v1.1/me/block/sites/\(siteID)/delete")) { _ in
            HTTPStubsResponse(jsonObject: ["success": 1], statusCode: 200, headers: nil)
        }

        waitUntil { done in
            service.flagSite(
                withID: siteID,
                asBlocked: false,
                success: {
                    done()
                },
                failure: { error in
                    // We call done in this failure scenario because we explicitly fail afterwards.
                    // Without this call, the test would have two failures:
                    // one because done was not called (timeout) and the explicit fail with error
                    done()
                    fail("Expected call to succeed. Failed with \(error?.localizedDescription ?? "'nil-error'")")
                }
            )
        }
    }

    func testFlagAsUnblockedFailurePath() {
        let service = makeService()
        let siteID: NSNumber = 42

        stub(condition: isPath("/rest/v1.1/me/block/sites/\(siteID)/delete")) { _ in
            HTTPStubsResponse(jsonObject: ["success": 0], statusCode: 200, headers: nil)
        }

        waitUntil { done in
            service.flagSite(
                withID: siteID,
                asBlocked: false,
                success: {
                    // We call done in this failure scenario because we explicitly fail afterwards.
                    // Without this call, the test would have two failures:
                    // one because done was not called (timeout) and the explicit fail with error
                    done()
                    fail("Expected call to fail, but succeeded")
                },
                failure: { error in
                    expect((error as? NSError)?.domain) == ReaderSiteServiceRemoteErrorDomain
                    expect((error as? NSError)?.code) == Int(ReaderSiteServiceRemoteError.sErviceRemoteUnsuccessfulBlockSite.rawValue)
                    done()
                }
            )
        }
    }
}

extension ReaderSiteServiceTests {

    func makeService(
        username: String = "testuser",
        authToken: String = "authtoken"
    ) -> ReaderSiteService {
        return makeService(username: username, authToken: authToken, contextManager: contextManager)
    }

    func makeService(
        username: String,
        authToken: String,
        contextManager: ContextManager
    ) -> ReaderSiteService {
        let accountService = AccountService(coreDataStack: contextManager)
        accountService.createOrUpdateAccount(withUsername: username, authToken: authToken)
        return ReaderSiteService(coreDataStack: contextManager)
    }
}

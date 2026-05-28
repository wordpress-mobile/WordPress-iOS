import OHHTTPStubs
import OHHTTPStubsSwift
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
        service.followSite(by: URL(string: "https://test.blog")!, success: success.fulfill, failure: { _ in })
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
        service.followSite(withID: 42, success: success.fulfill, failure: { _ in })
        wait(for: [success], timeout: 0.5)
    }

    func testUnfollowSiteByID() {
        stub(condition: isPath("/rest/v1.1/sites/42/follows/mine/delete")) { _ in
            HTTPStubsResponse(jsonObject: [String: Any](), statusCode: 200, headers: nil)
        }

        let service = makeService()
        let success = expectation(description: "The success block should be called")
        service.unfollowSite(withID: 42, success: success.fulfill, failure: { _ in })
        wait(for: [success], timeout: 0.5)
    }

    func testFlagAsBlockedSuccessPath() {
        let service = makeService()
        let siteID: NSNumber = 42

        stub(condition: isPath("/rest/v1.1/me/block/sites/\(siteID)/new")) { _ in
            HTTPStubsResponse(jsonObject: ["success": 1], statusCode: 200, headers: nil)
        }

        let exp = expectation(description: "flagSite blocked success")
        service.flagSite(
            withID: siteID,
            asBlocked: true,
            success: {
                exp.fulfill()
            },
            failure: { error in
                exp.fulfill()
                XCTFail("Expected call to succeed. Failed with \(error?.localizedDescription ?? "'nil-error'")")
            }
        )
        wait(for: [exp], timeout: 1)
    }

    func testFlagAsBlockedFailurePath() {
        let service = makeService()
        let siteID: NSNumber = 42

        stub(condition: isPath("/rest/v1.1/me/block/sites/\(siteID)/new")) { _ in
            HTTPStubsResponse(jsonObject: ["success": 0], statusCode: 200, headers: nil)
        }

        let exp = expectation(description: "flagSite blocked failure")
        service.flagSite(
            withID: siteID,
            asBlocked: true,
            success: {
                exp.fulfill()
                XCTFail("Expected call to fail, but succeeded")
            },
            failure: { error in
                XCTAssertEqual((error as? NSError)?.domain, ReaderSiteServiceRemoteErrorDomain)
                XCTAssertEqual((error as? NSError)?.code, Int(ReaderSiteServiceRemoteError.sErviceRemoteUnsuccessfulBlockSite.rawValue))
                exp.fulfill()
            }
        )
        wait(for: [exp], timeout: 1)
    }

    func testFlagAsUnblockedSuccessPath() {
        let service = makeService()
        let siteID: NSNumber = 42

        stub(condition: isPath("/rest/v1.1/me/block/sites/\(siteID)/delete")) { _ in
            HTTPStubsResponse(jsonObject: ["success": 1], statusCode: 200, headers: nil)
        }

        let exp = expectation(description: "flagSite unblocked success")
        service.flagSite(
            withID: siteID,
            asBlocked: false,
            success: {
                exp.fulfill()
            },
            failure: { error in
                exp.fulfill()
                XCTFail("Expected call to succeed. Failed with \(error?.localizedDescription ?? "'nil-error'")")
            }
        )
        wait(for: [exp], timeout: 1)
    }

    func testFlagAsUnblockedFailurePath() {
        let service = makeService()
        let siteID: NSNumber = 42

        stub(condition: isPath("/rest/v1.1/me/block/sites/\(siteID)/delete")) { _ in
            HTTPStubsResponse(jsonObject: ["success": 0], statusCode: 200, headers: nil)
        }

        let exp = expectation(description: "flagSite unblocked failure")
        service.flagSite(
            withID: siteID,
            asBlocked: false,
            success: {
                exp.fulfill()
                XCTFail("Expected call to fail, but succeeded")
            },
            failure: { error in
                XCTAssertEqual((error as? NSError)?.domain, ReaderSiteServiceRemoteErrorDomain)
                XCTAssertEqual((error as? NSError)?.code, Int(ReaderSiteServiceRemoteError.sErviceRemoteUnsuccessfulBlockSite.rawValue))
                exp.fulfill()
            }
        )
        wait(for: [exp], timeout: 1)
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

import OHHTTPStubs
import WordPress
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

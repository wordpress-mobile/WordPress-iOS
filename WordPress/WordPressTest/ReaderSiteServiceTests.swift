import XCTest
import OHHTTPStubs

class ReaderSiteServiceTests: CoreDataTestCase {

    private var service: ReaderSiteService!

    override func setUp() {
        let accountService = AccountService(coreDataStack: contextManager)
        accountService.createOrUpdateAccount(withUsername: "testuser", authToken: "authtoken")
        self.service = ReaderSiteService(coreDataStack: contextManager)

        stub(condition: isHost("public-api.wordpress.com")) { request in
            NSLog("[Warning] Received an unexpected request sent to \(String(describing: request.url))")
            return HTTPStubsResponse(error: URLError(.notConnectedToInternet))
        }
        HTTPStubs.removeAllStubs()
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

        let success = expectation(description: "The success block should be called")
        self.service.followSite(by: URL(string: "https://test.blog")!, success: success.fulfill, failure: nil)
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

        let success = expectation(description: "The success block should be called")
        self.service.followSite(withID: 42, success: success.fulfill, failure: nil)
        wait(for: [success], timeout: 0.5)
    }

    func testUnfollowSiteByID() {
        stub(condition: isPath("/rest/v1.1/sites/42/follows/mine/delete")) { _ in
            HTTPStubsResponse(jsonObject: [String: Any](), statusCode: 200, headers: nil)
        }

        let success = expectation(description: "The success block should be called")
        self.service.unfollowSite(withID: 42, success: success.fulfill, failure: nil)
        wait(for: [success], timeout: 0.5)
    }

}

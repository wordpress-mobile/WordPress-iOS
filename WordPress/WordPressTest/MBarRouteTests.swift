import XCTest
import OHHTTPStubs
@testable import WordPress

struct MockRouter: LinkRouter {
    let matcher: RouteMatcher
    var completion: ((URL, DeepLinkSource?) -> Void)?

    init(routes: [Route]) {
        self.matcher = RouteMatcher(routes: routes)
    }

    func canHandle(url: URL) -> Bool {
        return true
    }

    func handle(url: URL, shouldTrack track: Bool, source: DeepLinkSource?) {
        completion?(url, source)
    }
}

class MBarRouteTests: XCTestCase {

    private var router: MockRouter!
    private var route: MbarRoute!
    private var matcher: RouteMatcher!

    override func setUp() {
        super.setUp()

        let requestExpectation = expectation(description: "Request made to original URL")

        router = MockRouter(routes: [])
        route = MbarRoute()
        matcher = RouteMatcher(routes: [route])

        HTTPStubs.stubRequests(passingTest: isHost("public-api.wordpress.com")) { _ in
            defer {
                HTTPStubs.removeAllStubs()
                requestExpectation.fulfill()
            }

            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }
    }

    func testSingleLevelPostRedirect() throws {
        let url = URL(string: "https://public-api.wordpress.com/mbar?redirect_to=/post")!
        let success = expectation(description: "Correct redirect URL found")

        router.completion = { url, _ in
            if url.lastPathComponent == "post" {
                success.fulfill()
            }
        }

        if let match = matcher.routesMatching(url).first {
            match.action.perform(match.values,
                                 source: nil,
                                 router: router)
        }

        waitForExpectations(timeout: 1.0)
    }

    func testSingleLevelStartRedirectWithOtherParameters() throws {
        let url = URL(string: "https://public-api.wordpress.com/mbar?redirect_to=/start&stat=groovemails-events&bin=wpcom_email_click")!
        let success = expectation(description: "Correct redirect URL found")

        router.completion = { url, _ in
            if url.lastPathComponent == "start" {
                success.fulfill()
            }
        }

        if let match = matcher.routesMatching(url).first {
            match.action.perform(match.values,
                                 source: nil,
                                 router: router)
        }

        waitForExpectations(timeout: 1.0)
    }

    func testMultiLevelWPLoginRedirect() throws {
        let url = URL(string: "https://public-api.wordpress.com/mbar/?stat=groovemails-events&bin=wpcom_email_click&redirect_to=https://wordpress.com/wp-login.php?action=immediate-login%26timestamp=1617470831%26login_reason=user_first_flow%26user_id=123456789%26token=abcdef%26login_email=test%40example.com%26login_locale=en%26redirect_to=https%3A%2F%2Fwordpress.com%2Fstart%26sr=1%26signature=abcdef%26user=123456")!

        let success = expectation(description: "Correct redirect URL found")

        router.completion = { url, _ in
            if url.lastPathComponent == "start" {
                success.fulfill()
            }
        }

        if let match = matcher.routesMatching(url).first {
            match.action.perform(match.values,
                                 source: nil,
                                 router: router)
        }

        waitForExpectations(timeout: 1.0)
    }

    func testExtractEmailCampaignFromURL() throws {
        let url = URL(string: "https://public-api.wordpress.com/mbar/?stat=groovemails-events&bin=wpcom_email_click&redirect_to=https://wordpress.com/wp-login.php?action=immediate-login%26timestamp=1617470831%26login_reason=user_first_flow%26user_id=123456789%26token=abcdef%26login_email=test%40example.com%26login_locale=en%26redirect_to=https%3A%2F%2Fwordpress.com%2Fstart%26sr=1%26signature=abcdef%26user=123456")!
        let success = expectation(description: "Email campaign found")

        router.completion = { url, source in
            if url.lastPathComponent == "start",
               let trackingInfo = source?.trackingInfo,
               trackingInfo == "user_first_flow" {
                success.fulfill()
            }
        }

        if let match = matcher.routesMatching(url).first {
            match.action.perform(match.values,
                                 source: nil,
                                 router: router)
        }


        waitForExpectations(timeout: 1.0)
    }
}

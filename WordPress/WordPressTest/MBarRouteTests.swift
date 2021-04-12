import XCTest
@testable import WordPress

struct MockRouter: LinkRouter {
    let matcher: RouteMatcher
    var completion: ((URL) -> Void)?

    init(routes: [Route]) {
        self.matcher = RouteMatcher(routes: routes)
    }

    func canHandle(url: URL) -> Bool {
        return true
    }

    func handle(url: URL, shouldTrack track: Bool, source: UIViewController?) {
        completion?(url)
    }


}

class MBarRouteTests: XCTestCase {

    private var router: MockRouter!
    private var route: MbarRoute!
    private var matcher: RouteMatcher!

    override func setUp() {
        super.setUp()

        router = MockRouter(routes: [])
        route = MbarRoute()
        matcher = RouteMatcher(routes: [route])
    }

    func testSingleLevelPostRedirect() throws {
        let url = URL(string: "https://wordpress.com/mbar?redirect_to=/post")!
        let success = expectation(description: "Correct redirect URL found")

        router.completion = { url in
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
        let url = URL(string: "https://wordpress.com/mbar?redirect_to=/start&stat=groovemails-events&bin=wpcom_email_click")!
        let success = expectation(description: "Correct redirect URL found")

        router.completion = { url in
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
}

import XCTest
@testable import WordPress

class PublicizeAuthorizationURLComponentsTests: XCTestCase {
    override func setUp() {
    }

    override func tearDown() {
    }

    func testURLContainingAuthorizationPrefix() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?action=verify")!
        XCTAssertTrue(PublicizeAuthorizationURLComponents.authorizationPrefix.containedIn(url))
    }

    func testURLContainingVerifyActionParameter() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?action=verify")!
        XCTAssertTrue(PublicizeAuthorizationURLComponents.verifyActionParameter.containedIn(url))
    }

    func testURLContainingDenyActionParameter() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?action=deny")!
        XCTAssertTrue(PublicizeAuthorizationURLComponents.denyActionParameter.containedIn(url))
    }

    func testURLContainingRequestActionParameter() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?action=request")!
        XCTAssertTrue(PublicizeAuthorizationURLComponents.requestActionParameter.containedIn(url))
    }

    func testURLContainingDeclinePath() {
        let url = URL(string: "https://public-api.wordpress.com/connect/decline")!
        XCTAssertTrue(PublicizeAuthorizationURLComponents.declinePath.containedIn(url))
    }

    func testURLContainingAccessDeniedErrorParameter() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?error=access_denied")!
        XCTAssertTrue(PublicizeAuthorizationURLComponents.accessDenied.containedIn(url))
    }

    func testURLContainingStateParameter() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?state=abcdef&code=1234567")!
        XCTAssertTrue(PublicizeAuthorizationURLComponents.state.containedIn(url))
    }

    func testURLContainingCodeParameter() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?state=abcdef&code=1234567")!
        XCTAssertTrue(PublicizeAuthorizationURLComponents.code.containedIn(url))
    }

    func testURLContainingErrorParameter() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?state=abcdef&error=1234567")!
        XCTAssertTrue(PublicizeAuthorizationURLComponents.error.containedIn(url))
    }

    func testURLContainingUserRefusedParameter() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?oauth_problem=user_refused")!
        XCTAssertTrue(PublicizeAuthorizationURLComponents.userRefused.containedIn(url))
    }
}

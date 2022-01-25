import XCTest
@testable import WordPress

class PublicizeConnectionURLMatcherTests: XCTestCase {
    override func setUp() {
    }

    override func tearDown() {
    }

    func testURLContainingAuthorizationItem() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?action=verify")!
        XCTAssertTrue(PublicizeConnectionURLMatcher.authorizationPrefix.containedIn(url))
    }

    func testURLContainingVerifyActionItem() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?action=verify")!
        XCTAssertTrue(PublicizeConnectionURLMatcher.verifyActionItem.containedIn(url))
    }

    func testURLContainingDenyActionParameter() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?action=deny")!
        XCTAssertTrue(PublicizeConnectionURLMatcher.denyActionItem.containedIn(url))
    }

    func testURLContainingRequestActionItem() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?action=request")!
        XCTAssertTrue(PublicizeConnectionURLMatcher.requestActionItem.containedIn(url))
    }

    func testURLContainingDeclinePath() {
        let url = URL(string: "https://public-api.wordpress.com/connect/decline")!
        XCTAssertTrue(PublicizeConnectionURLMatcher.declinePath.containedIn(url))
    }

    func testURLContainingAccessDeniedErrorItem() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?error=access_denied")!
        XCTAssertTrue(PublicizeConnectionURLMatcher.accessDenied.containedIn(url))
    }

    func testURLContainingStateItem() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?state=abcdef&code=1234567")!
        XCTAssertTrue(PublicizeConnectionURLMatcher.stateItem.containedIn(url))
    }

    func testURLContainingCodeItem() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?state=abcdef&code=1234567")!
        XCTAssertTrue(PublicizeConnectionURLMatcher.codeItem.containedIn(url))
    }

    func testURLContainingErrorItemItem() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?state=abcdef&error=1234567")!
        XCTAssertTrue(PublicizeConnectionURLMatcher.errorItem.containedIn(url))
    }

    func testURLContainingUserRefusedParameter() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?oauth_problem=user_refused")!
        XCTAssertTrue(PublicizeConnectionURLMatcher.userRefused.containedIn(url))
    }
}

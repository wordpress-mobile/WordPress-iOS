import XCTest
@testable import WordPress

class PublicizeConnectionURLMatcherTests: XCTestCase {
    override func setUp() {
    }

    override func tearDown() {
    }

    func testURLContainingAuthorizationItem() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?action=verify")!
        XCTAssertTrue(PublicizeConnectionURLMatcher.url(url, contains: .authorizationPrefix))
    }

    func testURLContainingVerifyActionItem() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?action=verify")!
        XCTAssertTrue(PublicizeConnectionURLMatcher.url(url, contains: .verifyActionItem))
    }

    func testURLContainingDenyActionParameter() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?action=deny")!
        XCTAssertTrue(PublicizeConnectionURLMatcher.url(url, contains: .denyActionItem))
    }

    func testURLContainingRequestActionItem() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?action=request")!
        XCTAssertTrue(PublicizeConnectionURLMatcher.url(url, contains: .requestActionItem))
    }

    func testURLContainingDeclinePath() {
        let url = URL(string: "https://public-api.wordpress.com/connect/decline")!
        XCTAssertTrue(PublicizeConnectionURLMatcher.url(url, contains: .declinePath))
    }

    func testURLContainingAccessDeniedErrorItem() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?error=access_denied")!
        XCTAssertTrue(PublicizeConnectionURLMatcher.url(url, contains: .accessDenied))
    }

    func testURLContainingStateItem() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?state=abcdef&code=1234567")!
        XCTAssertTrue(PublicizeConnectionURLMatcher.url(url, contains: .stateItem))
    }

    func testURLContainingCodeItem() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?state=abcdef&code=1234567")!
        XCTAssertTrue(PublicizeConnectionURLMatcher.url(url, contains: .codeItem))
    }

    func testURLContainingErrorItemItem() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?state=abcdef&error=1234567")!
        XCTAssertTrue(PublicizeConnectionURLMatcher.url(url, contains: .errorItem))
    }

    func testURLContainingUserRefusedParameter() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?oauth_problem=user_refused")!
        XCTAssertTrue(PublicizeConnectionURLMatcher.url(url, contains: .userRefused))
    }
}

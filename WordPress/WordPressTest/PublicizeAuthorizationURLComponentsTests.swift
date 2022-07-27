import XCTest
@testable import WordPress

class PublicizeConnectionURLMatcherTests: XCTestCase {
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

    func testURLContainingErrorItem() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?state=abcdef&error=1234567")!
        XCTAssertTrue(PublicizeConnectionURLMatcher.url(url, contains: .errorItem))
    }

    func testURLContainingUserRefusedParameter() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?oauth_problem=user_refused")!
        XCTAssertTrue(PublicizeConnectionURLMatcher.url(url, contains: .userRefused))
    }

    // MARK: - Authorize Actions

    func testAuthorizeActionForDeclineURL() {
        let url = URL(string: "https://public-api.wordpress.com/decline?state=test")!
        XCTAssertEqual(PublicizeConnectionURLMatcher.authorizeAction(for: url), .deny)
    }

    func testAuthorizeActionWhenNoAuthorizationPrefix() {
        let url = URL(string: "https://public-api.wordpress.com/example")!
        XCTAssertEqual(PublicizeConnectionURLMatcher.authorizeAction(for: url), .none)
    }

    func testAuthorizeActionForVerifyAction() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?action=verify")!
        XCTAssertEqual(PublicizeConnectionURLMatcher.authorizeAction(for: url), .verify)
    }

    func testAuthorizeActionForDenyAction() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?action=deny")!
        XCTAssertEqual(PublicizeConnectionURLMatcher.authorizeAction(for: url), .deny)
    }

    func testAuthorizeActionForRequestAction() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?action=request")!
        XCTAssertEqual(PublicizeConnectionURLMatcher.authorizeAction(for: url), .request)
    }

    func testAuthorizeActionWhenUserRefused() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?oauth_problem=user_refused")!
        XCTAssertEqual(PublicizeConnectionURLMatcher.authorizeAction(for: url), .deny)
    }

    func testAuthorizeActionWhenAccessDenied() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?error=access_denied")!
        XCTAssertEqual(PublicizeConnectionURLMatcher.authorizeAction(for: url), .deny)
    }

    func testAuthorizeActionForFacebook() {
        let successURL = URL(string: "https://public-api.wordpress.com/connect/?state=1234&code=abcd")!
        XCTAssertEqual(PublicizeConnectionURLMatcher.authorizeAction(for: successURL), .verify)

        // Ensure code must be present
        let unknownURL = URL(string: "https://public-api.wordpress.com/connect/?state=1234")!
        XCTAssertEqual(PublicizeConnectionURLMatcher.authorizeAction(for: unknownURL), .unknown)

        // Error case
        let errorURL = URL(string: "https://public-api.wordpress.com/connect/?state=1234&error=abcd")!
        XCTAssertEqual(PublicizeConnectionURLMatcher.authorizeAction(for: errorURL), .unknown)
    }
}

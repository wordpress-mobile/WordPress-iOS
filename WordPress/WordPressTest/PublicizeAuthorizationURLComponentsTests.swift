import XCTest
@testable import WordPress

class PublicizeAuthorizationURLComponentsTests: XCTestCase {
    override func setUp() {
    }

    override func tearDown() {
    }

    func testURLContainingAuthorizationItem() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?action=verify")!
        XCTAssertTrue(PublicizeAuthorizationURLComponents.authorizationPrefix.containedIn(url))
    }

    func testURLContainingVerifyActionItem() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?action=verify")!
        XCTAssertTrue(PublicizeAuthorizationURLComponents.verifyActionItem.containedIn(url))
    }

    func testURLContainingDenyActionParameter() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?action=deny")!
        XCTAssertTrue(PublicizeAuthorizationURLComponents.denyActionItem.containedIn(url))
    }

    func testURLContainingRequestActionItem() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?action=request")!
        XCTAssertTrue(PublicizeAuthorizationURLComponents.requestActionItem.containedIn(url))
    }

    func testURLContainingDeclinePath() {
        let url = URL(string: "https://public-api.wordpress.com/connect/decline")!
        XCTAssertTrue(PublicizeAuthorizationURLComponents.declinePath.containedIn(url))
    }

    func testURLContainingAccessDeniedErrorItem() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?error=access_denied")!
        XCTAssertTrue(PublicizeAuthorizationURLComponents.accessDenied.containedIn(url))
    }

    func testURLContainingStateItem() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?state=abcdef&code=1234567")!
        XCTAssertTrue(PublicizeAuthorizationURLComponents.stateItem.containedIn(url))
    }

    func testURLContainingCodeItem() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?state=abcdef&code=1234567")!
        XCTAssertTrue(PublicizeAuthorizationURLComponents.codeItem.containedIn(url))
    }

    func testURLContainingErrorItemItem() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?state=abcdef&error=1234567")!
        XCTAssertTrue(PublicizeAuthorizationURLComponents.errorItem.containedIn(url))
    }

    func testURLContainingUserRefusedParameter() {
        let url = URL(string: "https://public-api.wordpress.com/connect/?oauth_problem=user_refused")!
        XCTAssertTrue(PublicizeAuthorizationURLComponents.userRefused.containedIn(url))
    }
}

import XCTest
@testable import WordPressAuthenticator

final class WordPressComSiteInfoTests: XCTestCase {
    private var subject: WordPressComSiteInfo!

    override func setUp() {
        subject = WordPressComSiteInfo(remote: mock())
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    func testJetpackActiveMatchesExpectation() {
        XCTAssertTrue(subject.isJetpackActive)
    }

    func testHasJetpackMatchesExpectation() {
        XCTAssertTrue(subject.hasJetpack)
    }

    func testJetpackConnectedMatchesExpectation() {
        XCTAssertTrue(subject.isJetpackConnected)
    }

    func testWPComMatchesExpectation() {
        XCTAssertFalse(subject.isWPCom)
    }

    func testWPMatchesExpectation() {
        XCTAssertTrue(subject.isWP)
    }
}

private extension WordPressComSiteInfoTests {
    func mock() -> [AnyHashable: Any] {
        return [
            "isJetpackActive": true,
            "jetpackVersion": false,
            "isWordPressDotCom": false,
            "urlAfterRedirects": "https://somewhere.com",
            "hasJetpack": true,
            "isWordPress": true,
            "isJetpackConnected": true
        ] as [AnyHashable: Any]
    }
}

import XCTest

class PasteboardTests: XCTestCase {
    let timeout = TimeInterval(3)

    override class func tearDown() {
        super.tearDown()
        let pasteboard = UIPasteboard.general
        pasteboard.string = ""
    }

    func testNominalAuthCode() throws {
        if #available(iOS 16.0, *) {
            throw XCTSkip("UIPasteboard doesn't work in iOS 16.0.") // Check https://github.com/wordpress-mobile/WordPressAuthenticator-iOS/issues/696
        }

        guard #available(iOS 14.0, *) else {
            throw XCTSkip("Unsupported iOS version")
        }

        let expect = expectation(description: "Could read nominal auth code from pasteboard")
        let pasteboard = UIPasteboard.general
        pasteboard.string = "123456"

        UIPasteboard.general.detectAuthenticatorCode { result in
            switch result {
                case .success(let authenticationCode):
                    XCTAssertEqual(authenticationCode, "123456")
                case .failure:
                    XCTAssert(false)
            }
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testLeadingZeroInAuthCodePreserved() throws {
        if #available(iOS 16.0, *) {
            throw XCTSkip("UIPasteboard doesn't work in iOS 16.0.") // Check https://github.com/wordpress-mobile/WordPressAuthenticator-iOS/issues/696
        }

        guard #available(iOS 14.0, *) else {
            throw XCTSkip("Unsupported iOS version")
        }

        let expect = expectation(description: "Could read leading zero auth code from pasteboard")
        let pasteboard = UIPasteboard.general
        pasteboard.string = "012345"

        UIPasteboard.general.detectAuthenticatorCode { result in
            switch result {
                case .success(let authenticationCode):
                    XCTAssertEqual(authenticationCode, "012345")
                case .failure:
                    XCTAssert(false)
            }
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }
}

import XCTest
@testable import WordPress

class QRLoginURLParserTests: XCTestCase {
    /// Test to make sure isValidHost returns true when passed a valid URL host
    func testIsValidHostSuccess() {
        let url = URL(string: "https://apps.wordpress.com")!
        XCTAssertTrue(QRLoginURLParser.isValidHost(url: url))
    }

    /// Test to make sure isValidHost returns false when passed a URL with an unsupported host
    func testIsValidHostFailure() {
        let url = URL(string: "https://wordpress.com")!
        XCTAssertFalse(QRLoginURLParser.isValidHost(url: url))
    }

    /// Make sure the parser does not return nil when it successfully parses a URL
    func testParserSuccess() {
        let urlString = "https://apps.wordpress.com?#qr-code-login?token=hello&data=world"
        let parser = QRLoginURLParser(urlString: urlString)

        XCTAssertNotNil(parser.parse())
    }

    /// Make sure the parser returns nil when it can't parse a URL
    func testParserFailure() {
        let urlString = "https://apps.wordpress.com?token=shouldnt&data=work"
        let parser = QRLoginURLParser(urlString: urlString)

        XCTAssertNil(parser.parse())
    }

    /// Make sure the QRLoginToken values are set correctly
    func testLoginTokenIsValid() {
        let token = "hello"
        let data = "world"

        let urlString = "https://apps.wordpress.com?#qr-code-login?token=\(token)&data=\(data)"
        let parser = QRLoginURLParser(urlString: urlString)
        let loginToken = parser.parse()

        XCTAssertNotNil(loginToken)
        XCTAssertEqual(loginToken!.token, token)
        XCTAssertEqual(loginToken!.data, data)
    }
}

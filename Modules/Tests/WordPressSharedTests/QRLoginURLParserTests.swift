import Foundation
import Testing
@testable import WordPressShared

struct QRLoginURLParserTests {
    /// Test to make sure isValidHost returns true when passed a valid URL host
    @Test func testIsValidHostSuccess() {
        let url = URL(string: "https://apps.wordpress.com")!
        #expect(QRLoginURLParser.isValidHost(url: url))
    }

    /// Test to make sure isValidHost returns false when passed a URL with an unsupported host
    @Test func testIsValidHostFailure() {
        let url = URL(string: "https://wordpress.com")!
        #expect(!(QRLoginURLParser.isValidHost(url: url)))
    }

    /// Make sure the parser does not return nil when it successfully parses a URL
    @Test func testParserSuccess() {
        let urlString = "https://apps.wordpress.com?#qr-code-login?token=hello&data=world"
        let parser = QRLoginURLParser(urlString: urlString)

        #expect(parser.parse() != nil)
    }

    /// Make sure the parser returns nil when it can't parse a URL
    @Test func testParserFailure() {
        let urlString = "https://apps.wordpress.com?token=shouldnt&data=work"
        let parser = QRLoginURLParser(urlString: urlString)

        #expect(parser.parse() == nil)
    }

    /// Make sure the QRLoginToken values are set correctly
    @Test func testLoginTokenIsValid() {
        let token = "hello"
        let data = "world"

        let urlString = "https://apps.wordpress.com?#qr-code-login?token=\(token)&data=\(data)"
        let parser = QRLoginURLParser(urlString: urlString)
        let loginToken = parser.parse()

        #expect(loginToken != nil)
        #expect(loginToken!.token == token)
        #expect(loginToken!.data == data)
    }
}

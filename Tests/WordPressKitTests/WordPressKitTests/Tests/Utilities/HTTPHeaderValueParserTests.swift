import Foundation
import XCTest

@testable import WordPressKit

class HTTPHeaderValueParserTests: XCTestCase {

    func testReturnOriginalCase() {
        XCTAssertEqual(
            HTTPURLResponse.value(ofParameter: "charset", inHeaderValue: "application/json; charset=UtF-8"),
            "UtF-8"
        )
    }

    func testCaseInsensitiveParameter() {
        XCTAssertEqual(
            HTTPURLResponse.value(ofParameter: "CharSet", inHeaderValue: "application/json; charset=utf-8"),
            "utf-8"
        )
    }

    func testFirstParameter() {
        XCTAssertEqual(
            HTTPURLResponse.value(ofParameter: "CharSet", inHeaderValue: "application/json; charset=utf-8;"),
            "utf-8"
        )
    }

    func testMiddleParameter() {
        XCTAssertEqual(
            HTTPURLResponse.value(ofParameter: "CharSet", inHeaderValue: "application/json; charset=utf-8; foo=bar"),
            "utf-8"
        )
    }

    func testLastParameter() {
        XCTAssertEqual(
            HTTPURLResponse.value(ofParameter: "CharSet", inHeaderValue: "application/json; foo=bar; charset=utf-8;"),
            "utf-8"
        )
    }

    func testLastParameterWithoutSemicolon() {
        XCTAssertEqual(
            HTTPURLResponse.value(ofParameter: "CharSet", inHeaderValue: "application/json; charset=utf-8"),
            "utf-8"
        )
    }

    func testNoSpaceBetweenParameters() {
        XCTAssertEqual(
            HTTPURLResponse.value(ofParameter: "CharSet", inHeaderValue: "application/json;charset=utf-8;foo=bar"),
            "utf-8"
        )
    }

    func testParameterValueWithQuotes() {
        XCTAssertEqual(
            HTTPURLResponse.value(ofParameter: "rel", inHeaderValue: "https://wordpress.org/wp-json; rel=\"https://api.w.org\""),
            "https://api.w.org"
        )

        XCTAssertEqual(
            HTTPURLResponse.value(ofParameter: "rel", inHeaderValue: "https://wordpress.org/wp-json; rel=\"https://api.w.org\"", stripQuotes: false),
            "\"https://api.w.org\""
        )
    }

    func testValueWithoutParameters() {
        let response = HTTPURLResponse(url: URL(string: "https://site.com")!, statusCode: 200, httpVersion: "2", headerFields: [
            "Link": "https://site.com/wp-json; rel=\"https://api.w.org\"",
            "Content-Type": "text/html"
        ])

        XCTAssertEqual(response?.value(forHTTPHeaderField: "Link", withoutParameters: true), "https://site.com/wp-json")
        XCTAssertEqual(response?.value(forHTTPHeaderField: "Content-Type", withoutParameters: true), "text/html")
    }

}

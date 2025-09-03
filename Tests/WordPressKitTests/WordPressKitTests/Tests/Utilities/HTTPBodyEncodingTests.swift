import Foundation
import XCTest
@testable import WordPressKit

class HTTPBodyEncodingTests: XCTestCase {

    func testRoundTrip() throws {
        // The test strings are generated using the following command line:
        // $ echo -n "👋" | iconv -f UTF-8 -t <charset> | base64

        XCTAssertEqual(try decode(base64EncodedBody: "8J+Riw==", charset: "UTF-8"), "👋")
        XCTAssertEqual(try decode(base64EncodedBody: "2D3cSw==", charset: "UTF-16BE"), "👋")
        XCTAssertEqual(try decode(base64EncodedBody: "PdhL3A==", charset: "UTF-16LE"), "👋")
    }

    private func decode(base64EncodedBody: String, charset: String, file: StaticString = #file, line: UInt = #line) throws -> String? {
        let response = try XCTUnwrap(HTTPURLResponse(url: URL(string: "https://wordpress.org")!, statusCode: 200, httpVersion: "2", headerFields: [
            "Content-Type": "text/html; charset=\(charset)"
        ]))
        let originalBodyData = try XCTUnwrap(Data(base64Encoded: base64EncodedBody))
        return HTTPAPIResponse(response: response, body: originalBodyData).bodyText
    }

}

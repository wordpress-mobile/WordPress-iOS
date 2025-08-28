import Foundation
import XCTest
@testable import WordPressKit

class WordPressAPIErrorTests: XCTestCase {

    func testLocalizedMessage() {

        let error = WordPressAPIError.endpointError(TestError())
        XCTAssertEqual(error.errorDescription, "this is a test error")
        XCTAssertEqual((error as NSError).localizedDescription, "this is a test error")
    }

    func testNilErrorDescription() {
        struct TestError: LocalizedError {
            var errorDescription: String? = nil
        }

        let error = WordPressAPIError.endpointError(TestError())
        XCTAssertEqual(error.localizedDescription, WordPressAPIError<TestError>.unknownErrorMessage)
        XCTAssertEqual((error as NSError).localizedDescription, WordPressAPIError<TestError>.unknownErrorMessage)
    }

    func testGettingHTTPResponse() {
        typealias APIError = WordPressAPIError<TestError>

        let response = HTTPURLResponse(url: URL(string: "https//w.org")!, statusCode: 200, httpVersion: "2", headerFields: nil)!

        XCTAssertNil(APIError.requestEncodingFailure(underlyingError: URLError(.badURL)).response)
        XCTAssertNil(APIError.connection(URLError(.badURL)).response)
        XCTAssertIdentical(APIError.endpointError(.init(httpResponse: response)).response, response)
        XCTAssertIdentical(APIError.unacceptableStatusCode(response: response, body: Data()).response, response)
        XCTAssertIdentical(APIError.unparsableResponse(response: response, body: Data()).response, response)
        XCTAssertNil(APIError.unknown(underlyingError: URLError(.badURL)).response)
    }

}

private struct TestError: LocalizedError, HTTPURLResponseProviding {
    var errorDescription: String? = "this is a test error"

    var httpResponse: HTTPURLResponse?
}

import XCTest
#if SWIFT_PACKAGE
import APIInterface
@testable import CoreAPI
#else
@testable import WordPressKit
#endif

class WordPressComRestApiErrorTests: XCTestCase {

    func testNSErrorBridging() {
        for error in WordPressComRestApiErrorCode.allCases {
            let apiError = WordPressAPIError.endpointError(WordPressComRestApiEndpointError(code: error))
            let newNSError = apiError as NSError

            XCTAssertEqual(newNSError.domain, "WordPressKit.WordPressComRestApiError")
            XCTAssertEqual(newNSError.code, error.rawValue)
        }
    }

    func testErrorDomain() {
        XCTAssertEqual(WordPressComRestApiErrorDomain, WordPressComRestApiEndpointError.errorDomain)
    }

}

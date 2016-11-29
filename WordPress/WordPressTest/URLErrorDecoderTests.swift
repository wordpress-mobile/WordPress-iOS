import Foundation
import XCTest
@testable import WordPress

class URLErrorDecoderTests: XCTestCase {

    func testCantFindHostError() {

        let error = NSError(domain: "", code: NSURLErrorCannotFindHost, userInfo: nil)
        let decoder = URLErrorDecoder(error: error)
        XCTAssertTrue(decoder.hasInternetConnectionRelatedError())
    }

    func testCantConnectToHostError() {

        let error = NSError(domain: "", code: NSURLErrorCannotConnectToHost, userInfo: nil)
        let decoder = URLErrorDecoder(error: error)
        XCTAssertTrue(decoder.hasInternetConnectionRelatedError())
    }

    func testNetworkConnectionLostError() {

        let error = NSError(domain: "", code: NSURLErrorNetworkConnectionLost, userInfo: nil)
        let decoder = URLErrorDecoder(error: error)
        XCTAssertTrue(decoder.hasInternetConnectionRelatedError())
    }

    func testNotConnectedToInternetError() {

        let error = NSError(domain: "", code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        let decoder = URLErrorDecoder(error: error)
        XCTAssertTrue(decoder.hasInternetConnectionRelatedError())
    }

    func testNotAInternetConnectionError() {

        let error = NSError(domain: "", code: NSURLErrorUnsupportedURL, userInfo: nil)
        let decoder = URLErrorDecoder(error: error)
        XCTAssertFalse(decoder.hasInternetConnectionRelatedError())
    }
}

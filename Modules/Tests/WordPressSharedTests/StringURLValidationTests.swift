import XCTest
@testable import WordPressShared

class StringURLValidationTests: XCTestCase {

    // MARK: - Invalid URLs

    func testInvalidURLs() {
        let urls = [
            "invalidurl",
            "123123",
            "wwwwordpresscom"]

        for url in urls {
            guard !url.isValidURL() else {
                XCTFail("\(url) is valid (expected invalid).")
                continue
            }
        }
    }

    // MARK: - Valid URLs

    func testValidURLs() {
        let urls = [
            "https://cheese-pc",
            "https://localhost",
            "www.wordpress.com",
            "http://www.wordpress.com"]

        for url in urls {
            guard url.isValidURL() else {
                XCTFail("\(url) is invalid (expected valid).")
                continue
            }
        }
    }
}

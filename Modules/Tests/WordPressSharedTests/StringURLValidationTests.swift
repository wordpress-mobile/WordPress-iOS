import Testing
@testable import WordPressShared

struct StringURLValidationTests {

    // MARK: - Invalid URLs

    @Test func testInvalidURLs() {
        let urls = [
            "invalidurl",
            "123123",
            "wwwwordpresscom"]

        for url in urls {
            guard !url.isValidURL() else {
                Issue.record("\(url) is valid (expected invalid).")
                continue
            }
        }
    }

    // MARK: - Valid URLs

    @Test func testValidURLs() {
        let urls = [
            "https://cheese-pc",
            "https://localhost",
            "www.wordpress.com",
            "http://www.wordpress.com"]

        for url in urls {
            guard url.isValidURL() else {
                Issue.record("\(url) is invalid (expected valid).")
                continue
            }
        }
    }
}

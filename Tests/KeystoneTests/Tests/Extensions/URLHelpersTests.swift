import XCTest
import WordPress

class URLHelpersTests: XCTestCase {

    func testAddCacheBusterToExistingQueryParameters() async throws {
        try await doTest("https://gravatar.com/avatar/1234?s=80")
    }

    func testAddCacheBusterToCanonicalURL() async throws {
        try await doTest("https://gravatar.com")
    }

    func doTest(_ urlString: String) async throws {
        let url = try XCTUnwrap(URL(string: urlString))
        let newURL = url.appendingGravatarCacheBusterParam()
        XCTAssertNotEqual(url.absoluteString, newURL.absoluteString)

        let components = URLComponents(url: newURL, resolvingAgainstBaseURL: false)
        let cacheBusterQueryItem = components?.queryItems?.filter { $0.name == "_" }.first
        XCTAssertNotNil(cacheBusterQueryItem?.value)
    }
}

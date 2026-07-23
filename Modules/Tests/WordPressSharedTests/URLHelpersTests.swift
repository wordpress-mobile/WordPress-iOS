import Foundation
import Testing
import WordPressShared

struct URLHelpersTests {

    @Test func testAddCacheBusterToExistingQueryParameters() async throws {
        try await doTest("https://gravatar.com/avatar/1234?s=80")
    }

    @Test func testAddCacheBusterToCanonicalURL() async throws {
        try await doTest("https://gravatar.com")
    }

    func doTest(_ urlString: String) async throws {
        let url = try #require(URL(string: urlString))
        let newURL = url.appendingGravatarCacheBusterParam()
        #expect(url.absoluteString != newURL.absoluteString)

        let components = URLComponents(url: newURL, resolvingAgainstBaseURL: false)
        let cacheBusterQueryItem = components?.queryItems?.first(where: { $0.name == "_" })
        #expect(cacheBusterQueryItem?.value != nil)
    }
}

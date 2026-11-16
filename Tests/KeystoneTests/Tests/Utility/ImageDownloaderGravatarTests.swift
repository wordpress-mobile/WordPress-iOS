import AsyncImageKit
import Foundation
import Testing

@testable import WordPress

struct ImageDownloaderGravatarTests {

    @Test("the account avatar URL requests 192 pixels, any rating, and a 404 for a missing avatar")
    func accountAvatarURL() throws {
        let url = try #require(ImageDownloader.accountAvatarURL(for: "a@example.com"))
        let items = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        let query = Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })

        #expect(query["s"] == "192")
        #expect(query["r"] == "x")
        #expect(query["d"] == "404")
        #expect(query["_"] == nil)
    }

    @Test("only a 404 means a missing gravatar")
    func missingGravatar() {
        #expect(ImageDownloader.isMissingGravatar(ImageDownloaderError.unacceptableStatusCode(404)))
        #expect(!ImageDownloader.isMissingGravatar(ImageDownloaderError.unacceptableStatusCode(500)))
        #expect(!ImageDownloader.isMissingGravatar(ImageDownloaderError.unacceptableStatusCode(nil)))
        #expect(!ImageDownloader.isMissingGravatar(URLError(.notConnectedToInternet)))
    }
}

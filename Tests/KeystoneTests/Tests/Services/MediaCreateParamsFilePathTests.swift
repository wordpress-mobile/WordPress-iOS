import Foundation
import Testing
import WordPressAPI
import WordPressKit

@testable import WordPress

/// `URL.path()` percent-encodes by default, unlike the legacy `url.path` property, so the
/// upload API was handed a path that doesn't exist on disk whenever the filename needed
/// encoding. A space is enough, which makes it reachable with ordinary content.
struct MediaCreateParamsFilePathTests {

    @Test func decodesPercentEncodingInTheFilePath() throws {
        let media = RemoteMedia()
        media.localURL = URL(fileURLWithPath: "/tmp/media/screen recording 1.mp4")

        let params = try #require(MediaCreateParams(media: media))

        #expect(params.filePath == "/tmp/media/screen recording 1.mp4")
    }

    /// Characters beyond the space get encoded too, so check one of those as well.
    @Test func decodesPercentEncodingBeyondSpaces() throws {
        let media = RemoteMedia()
        media.localURL = URL(fileURLWithPath: "/tmp/media/100% done.jpg")

        let params = try #require(MediaCreateParams(media: media))

        #expect(params.filePath == "/tmp/media/100% done.jpg")
    }

    /// A name needing no encoding has to survive untouched.
    @Test func leavesAnOrdinaryPathAlone() throws {
        let media = RemoteMedia()
        media.localURL = URL(fileURLWithPath: "/tmp/media/IMG_0001.jpg")

        let params = try #require(MediaCreateParams(media: media))

        #expect(params.filePath == "/tmp/media/IMG_0001.jpg")
    }
}

import Foundation
import Testing
@testable import JetpackStats

/// Covers the sizing applied to a featured image before a stats row draws it.
@Suite
struct URLThumbnailTests {
    @Test("Resizes a WordPress.com image from query parameters, in pixels")
    func resizesDotcomImage() throws {
        let url = try #require(URL(string: "https://example.files.wordpress.com/2026/11/photo.jpg"))

        let sized = url.thumbnail(fillingSquareOf: 32, displayScale: 3)

        #expect(sized.absoluteString == "https://example.files.wordpress.com/2026/11/photo.jpg?w=96&h=96&crop=1")
    }

    @Test("Drops a size the URL already carried, so it can't stay too small")
    func replacesExistingQuery() throws {
        let url = try #require(URL(string: "https://example.files.wordpress.com/photo.jpg?w=10&quality=20"))

        let sized = url.thumbnail(fillingSquareOf: 32, displayScale: 2)

        #expect(sized.query == "w=64&h=64&crop=1")
    }

    @Test("Sends a self-hosted image through Photon, which crops to the asked-for size")
    func routesSelfHostedImageThroughPhoton() throws {
        let url = try #require(URL(string: "https://example.com/wp-content/uploads/photo.jpg"))

        let sized = url.thumbnail(fillingSquareOf: 32, displayScale: 2)

        #expect(sized.host == "i0.wp.com")
        #expect(sized.absoluteString.contains("resize=64,64"))
    }

    @Test("Leaves an image Photon can't resize alone, rather than breaking it")
    func keepsUnsupportedExtension() throws {
        let url = try #require(URL(string: "https://example.com/wp-content/uploads/photo.webp"))

        #expect(url.thumbnail(fillingSquareOf: 32, displayScale: 2) == url)
    }

    @Test(
        "Leaves the URL alone when there is no size to ask for",
        arguments: [(CGFloat(0), CGFloat(2)), (32, 0)] as [(CGFloat, CGFloat)]
    )
    func keepsURLWithoutAUsableSize(pointSize: CGFloat, displayScale: CGFloat) throws {
        let url = try #require(URL(string: "https://example.files.wordpress.com/photo.jpg"))

        #expect(url.thumbnail(fillingSquareOf: pointSize, displayScale: displayScale) == url)
    }
}

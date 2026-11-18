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
    func replacesExistingSize() throws {
        let url = try #require(URL(string: "https://example.files.wordpress.com/photo.jpg?w=10&h=10&crop=1"))

        let sized = url.thumbnail(fillingSquareOf: 32, displayScale: 2)

        #expect(sized.query == "w=64&h=64&crop=1")
    }

    @Test("Keeps a parameter that isn't a size, which may identify the image itself")
    func keepsNonSizingQueryItems() throws {
        let url = try #require(URL(string: "https://example.files.wordpress.com/photo.jpg?ssl=1&w=10&quality=20"))

        let sized = url.thumbnail(fillingSquareOf: 32, displayScale: 2)

        #expect(sized.query == "ssl=1&quality=20&w=64&h=64&crop=1")
    }

    @Test("Hands an image already behind Photon back to Photon, keeping ssl")
    func reusesPhotonForAPhotonURL() throws {
        let url = try #require(URL(string: "https://i0.wp.com/example.com/photo.jpg?ssl=1&w=10"))

        let sized = url.thumbnail(fillingSquareOf: 32, displayScale: 2)

        #expect(sized.host == "i0.wp.com")
        #expect(sized.path == "/example.com/photo.jpg")
        #expect(sized.absoluteString.contains("resize=64,64"))
        #expect(sized.absoluteString.contains("ssl=1"))
    }

    @Test("Sends a self-hosted image through Photon, which crops to the asked-for size")
    func routesSelfHostedImageThroughPhoton() throws {
        let url = try #require(URL(string: "https://example.com/wp-content/uploads/photo.jpg"))

        let sized = url.thumbnail(fillingSquareOf: 32, displayScale: 2)

        #expect(sized.host == "i0.wp.com")
        #expect(sized.absoluteString.contains("resize=64,64"))
    }

    @Test("Resizes a P2 image at the site's own domain, which Photon can't fetch")
    func resizesP2ImageAtItsOwnHost() throws {
        let url = try #require(URL(string: "https://team.example.com/wp-content/uploads/photo.jpg"))

        let sized = url.thumbnail(fillingSquareOf: 32, displayScale: 2, isWordPressComHosted: true)

        #expect(sized.host == "team.example.com")
        #expect(sized.query == "w=64&h=64&crop=1")
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

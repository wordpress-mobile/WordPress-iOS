import UIKit
import XCTest
import WordPressUI
@testable import WordPress

final class SiteIconViewModelTests: XCTestCase {
    // MARK: - Test `optimizedURL(for:)`

    /// Tests that a dotcom image URL with default image size is valid.
    func testDotcomURLWithDefaultSize() {
        // Given
        let url = Constants.dotcomURL

        // When
        let optimizedURL = SiteIconViewModel.optimizedURL(for: url)

        // Then
        let size = 40 * Int(UIScreen.main.scale)
        let expectedURL = URL(string: "\(url.absoluteString)?w=\(size)&h=\(size)")
        XCTAssertEqual(optimizedURL, expectedURL)
    }

    /// Tests that a gravatar image URL with default image size is valid.
    func testBlavatarURLWithDefaultSize() {
        // Given
        let url = Constants.gravatarURL

        // When
        let optimizedURL = SiteIconViewModel.optimizedURL(for: url)

        // Then
        let size = 40 * Int(UIScreen.main.scale)
        let expectedURL = URL(string: "\(url.absoluteString)?d=404&s=\(size)")
        XCTAssertEqual(optimizedURL, expectedURL)
    }

    /// Tests that a photon image URL with default image size is valid.
    func testPhotonURLWithDefaultSize() {
        // Given
        let url = Constants.photonURL

        // When
        let optimizedURL = SiteIconViewModel.optimizedURL(for: url)

        // Then
        let size = 40 * Int(UIScreen.main.scale)
        let expectedURL = URL(string: "\(url.absoluteString)?w=\(size)&h=\(size)")
        XCTAssertEqual(optimizedURL, expectedURL)
    }

    /// Tests that a dotcom image URL with custom image size is valid.
    func testDotcomURLWithCustomSize() {
        // Given
        let sizeInPoints = Constants.customImageSize
        let url = Constants.dotcomURL

        // When
        let optimizedURL = SiteIconViewModel.optimizedURL(for: url, imageSize: sizeInPoints)

        // Then
        let size = Int(sizeInPoints.width) * Int(UIScreen.main.scale)
        let expectedURL = URL(string: "\(url.absoluteString)?w=\(size)&h=\(size)")
        XCTAssertEqual(optimizedURL, expectedURL)
    }

    /// Tests that a gravatar image URL with custom image size is valid.
    func testBlavatarURLWithCustomSize() {
        // Given
        let sizeInPoints = Constants.customImageSize
        let url = Constants.gravatarURL

        // When
        let optimizedURL = SiteIconViewModel.optimizedURL(for: url, imageSize: sizeInPoints)

        // Then
        let size = Int(sizeInPoints.width) * Int(UIScreen.main.scale)
        let expectedURL = URL(string: "\(url.absoluteString)?d=404&s=\(size)")
        XCTAssertEqual(optimizedURL, expectedURL)
    }

    /// Tests that a photon image URL with custom image size is valid.
    func testPhotonURLWithCustomSize() {
        // Given
        let sizeInPoints = Constants.customImageSize
        let url = Constants.photonURL

        // When
        let optimizedURL = SiteIconViewModel.optimizedURL(for: url, imageSize: sizeInPoints)

        // Then
        let size = Int(sizeInPoints.width) * Int(UIScreen.main.scale)
        let expectedURL = URL(string: "\(url.absoluteString)?w=\(size)&h=\(size)")
        XCTAssertEqual(optimizedURL, expectedURL)
    }

    // MARK: - Host matching

    /// Tests that a third-party URL whose query mentions a WP.com host is still wrapped in Photon.
    func testLookalikeQueryIsNotTreatedAsDotcom() {
        // Given
        let url = URL(string: "https://attacker.example.com/icon.png?u=.files.wordpress.com")!

        // When
        let optimizedURL = SiteIconViewModel.optimizedURL(for: url)

        // Then
        XCTAssertEqual(optimizedURL?.host, "i0.wp.com")
    }

    /// Tests that a Gravatar-lookalike path on a third-party host is still wrapped in Photon.
    /// The path needs an image extension: `PhotonImageURLHelper` declines to wrap
    /// extension-less URLs and returns them unchanged.
    func testLookalikePathIsNotTreatedAsBlavatar() {
        // Given
        let url = URL(string: "https://attacker.example.com/gravatar.com/blavatar/123.png")!

        // When
        let optimizedURL = SiteIconViewModel.optimizedURL(for: url)

        // Then
        XCTAssertEqual(optimizedURL?.host, "i0.wp.com")
    }

    /// Tests that a WordPress.com subdomain is sized directly rather than wrapped in Photon.
    func testWPComSubdomainIsTreatedAsDotcom() {
        // Given
        let url = URL(string: "https://example.wordpress.com/icon.png")!

        // When
        let optimizedURL = SiteIconViewModel.optimizedURL(for: url)

        // Then
        let size = 40 * Int(UIScreen.main.scale)
        XCTAssertEqual(optimizedURL, URL(string: "\(url.absoluteString)?w=\(size)&h=\(size)"))
    }

    /// Tests that a URL relative to a base URL is resolved before its query is replaced.
    func testURLRelativeToBaseURLIsResolvedBeforeOptimization() {
        // Given
        let baseURL = URL(string: "https://example.wordpress.com")!
        let url = URL(string: "icon.png?existing=value", relativeTo: baseURL)!

        // When
        let optimizedURL = SiteIconViewModel.optimizedURL(for: url)

        // Then
        let size = 40 * Int(UIScreen.main.scale)
        XCTAssertEqual(optimizedURL, URL(string: "https://example.wordpress.com/icon.png?w=\(size)&h=\(size)"))
    }

    // MARK: - Constants

    private struct Constants {
        static let customImageSize = CGSize(width: 60, height: 60)
        static let dotcomURL = URL(string: "https://fake.files.wordpress.com/fake.png")!
        static let gravatarURL = URL(string: "https://secure.gravatar.com/blavatar/123")!
        static let photonURL = URL(string: "https://fake.wp.com/fake.png")!
    }
}

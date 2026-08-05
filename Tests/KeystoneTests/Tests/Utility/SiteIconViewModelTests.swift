import UIKit
import XCTest
import WordPressUI
@testable import WordPress

final class SiteIconViewModelTests: XCTestCase {
    // MARK: - Test `optimizedURL(for:)`

    /// Tests that a dotcom image URL with default image size is valid.
    func testDotcomURLWithDefaultSize() {
        // Given
        let path = Constants.dotcomPath

        // When
        let optimizedURL = SiteIconViewModel.optimizedURL(for: path)

        // Then
        let size = 40 * Int(UIScreen.main.scale)
        let expectedURL = URL(string: "\(path)?w=\(size)&h=\(size)")
        XCTAssertEqual(optimizedURL, expectedURL)
    }

    /// Tests that a gravatar image URL with default image size is valid.
    func testBlavatarURLWithDefaultSize() {
        // Given
        let path = Constants.gravatarPath

        // When
        let optimizedURL = SiteIconViewModel.optimizedURL(for: path)

        // Then
        let size = 40 * Int(UIScreen.main.scale)
        let expectedURL = URL(string: "\(path)?d=404&s=\(size)")
        XCTAssertEqual(optimizedURL, expectedURL)
    }

    /// Tests that a photon image URL with default image size is valid.
    func testPhotonURLWithDefaultSize() {
        // Given
        let path = Constants.photonPath

        // When
        let optimizedURL = SiteIconViewModel.optimizedURL(for: path)

        // Then
        let size = 40 * Int(UIScreen.main.scale)
        let expectedURL = URL(string: "\(path)?w=\(size)&h=\(size)")
        XCTAssertEqual(optimizedURL, expectedURL)
    }

    /// Tests that a dotcom image URL with custom image size is valid.
    func testDotcomURLWithCustomSize() {
        // Given
        let sizeInPoints = Constants.customImageSize
        let path = Constants.dotcomPath

        // When
        let optimizedURL = SiteIconViewModel.optimizedURL(for: path, imageSize: sizeInPoints)

        // Then
        let size = Int(sizeInPoints.width) * Int(UIScreen.main.scale)
        let expectedURL = URL(string: "\(path)?w=\(size)&h=\(size)")
        XCTAssertEqual(optimizedURL, expectedURL)
    }

    /// Tests that a gravatar image URL with custom image size is valid.
    func testBlavatarURLWithCustomSize() {
        // Given
        let sizeInPoints = Constants.customImageSize
        let path = Constants.gravatarPath

        // When
        let optimizedURL = SiteIconViewModel.optimizedURL(for: path, imageSize: sizeInPoints)

        // Then
        let size = Int(sizeInPoints.width) * Int(UIScreen.main.scale)
        let expectedURL = URL(string: "\(path)?d=404&s=\(size)")
        XCTAssertEqual(optimizedURL, expectedURL)
    }

    /// Tests that a photon image URL with custom image size is valid.
    func testPhotonURLWithCustomSize() {
        // Given
        let sizeInPoints = Constants.customImageSize
        let path = Constants.photonPath

        // When
        let optimizedURL = SiteIconViewModel.optimizedURL(for: path, imageSize: sizeInPoints)

        // Then
        let size = Int(sizeInPoints.width) * Int(UIScreen.main.scale)
        let expectedURL = URL(string: "\(path)?w=\(size)&h=\(size)")
        XCTAssertEqual(optimizedURL, expectedURL)
    }

    // MARK: - Host matching

    /// Tests that a third-party URL whose query mentions a WP.com host is still wrapped in Photon.
    func testLookalikeQueryIsNotTreatedAsDotcom() {
        // Given
        let path = "https://attacker.example.com/icon.png?u=.files.wordpress.com"

        // When
        let optimizedURL = SiteIconViewModel.optimizedURL(for: path)

        // Then
        XCTAssertEqual(optimizedURL?.host, "i0.wp.com")
    }

    /// Tests that a Gravatar-lookalike path on a third-party host is still wrapped in Photon.
    /// The path needs an image extension: `PhotonImageURLHelper` declines to wrap
    /// extension-less URLs and returns them unchanged.
    func testLookalikePathIsNotTreatedAsBlavatar() {
        // Given
        let path = "https://attacker.example.com/gravatar.com/blavatar/123.png"

        // When
        let optimizedURL = SiteIconViewModel.optimizedURL(for: path)

        // Then
        XCTAssertEqual(optimizedURL?.host, "i0.wp.com")
    }

    /// Tests that a WordPress.com subdomain is sized directly rather than wrapped in Photon.
    func testWPComSubdomainIsTreatedAsDotcom() {
        // Given
        let path = "https://example.wordpress.com/icon.png"

        // When
        let optimizedURL = SiteIconViewModel.optimizedURL(for: path)

        // Then
        let size = 40 * Int(UIScreen.main.scale)
        XCTAssertEqual(optimizedURL, URL(string: "\(path)?w=\(size)&h=\(size)"))
    }

    // MARK: - Constants

    private struct Constants {
        static let customImageSize = CGSize(width: 60, height: 60)
        static let dotcomPath = "https://fake.files.wordpress.com/fake.png"
        static let gravatarPath = "https://secure.gravatar.com/blavatar/123"
        static let photonPath = "https://fake.wp.com/fake.png"
    }
}

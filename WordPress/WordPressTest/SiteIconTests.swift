import UIKit
import XCTest

@testable import WordPress

final class SiteIconTests: XCTestCase {

    /// Instance to access the extension methods declared in `UIImageView+SiteIcon.swift`.
    /// Perhaps those methods should be static.
    let imageView = UIImageView()

    // MARK: - Test `optimizedURL(for:)`

    /// Tests that a dotcom image URL with default image size is valid.
    func testDotcomURLWithDefaultSize() {
        // Given
        let path =  Constants.dotcomPath

        // When
        let optimizedURL = imageView.optimizedURL(for: path)

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
        let optimizedURL = imageView.optimizedURL(for: path)

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
        let optimizedURL = imageView.optimizedURL(for: path)

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
        let optimizedURL = imageView.optimizedURL(for: path, imageSize: sizeInPoints)

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
        let optimizedURL = imageView.optimizedURL(for: path, imageSize: sizeInPoints)

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
        let optimizedURL = imageView.optimizedURL(for: path, imageSize: sizeInPoints)

        // Then
        let size = Int(sizeInPoints.width) * Int(UIScreen.main.scale)
        let expectedURL = URL(string: "\(path)?w=\(size)&h=\(size)")
        XCTAssertEqual(optimizedURL, expectedURL)
    }

    // MARK: - Constants

    private struct Constants {
        static let customImageSize = CGSize(width: 60, height: 60)
        static let dotcomPath = "https://fake.files.wordpress.com/fake.png"
        static let gravatarPath = "https://secure.gravatar.com/blavatar/123"
        static let photonPath = "https://fake.wp.com/fake.png"
    }
}

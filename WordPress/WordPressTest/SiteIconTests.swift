import UIKit
import XCTest

@testable import WordPress

final class SiteIconTests: XCTestCase {

    /// Instance to access the extension methods declared in `UIImageView+SiteIcon.swift`.
    /// Perhaps those methods should be static.
    let imageView = UIImageView()

    // MARK: - Test `optimizedURL(for:)`

    /// Tests that a dotcom image URL is valid.
    func testDotcomURL() {
        // Given
        let path = "https://fake.files.wordpress.com/fake.png"

        // When
        let optimizedURL = imageView.optimizedURL(for: path)

        // Then
        let size = 40 * Int(UIScreen.main.scale)
        let expectedURL = URL(string: "\(path)?w=\(size)&h=\(size)")
        XCTAssertEqual(optimizedURL, expectedURL)
    }

    /// Tests that a gravatar image URL is valid.
    func testBlavatarURL() {
        // Given
        let path = "https://secure.gravatar.com/blavatar/123"

        // When
        let optimizedURL = imageView.optimizedURL(for: path)

        // Then
        let size = 40 * Int(UIScreen.main.scale)
        let expectedURL = URL(string: "\(path)?d=404&s=\(size)")
        XCTAssertEqual(optimizedURL, expectedURL)
    }

    /// Tests that a photon image URL is valid.
    func testPhotonURL() {
        // Given
        let path = "https://fake.wp.com/fake.png"

        // When
        let optimizedURL = imageView.optimizedURL(for: path)

        // Then
        let size = 40 * Int(UIScreen.main.scale)
        let expectedURL = URL(string: "\(path)?w=\(size)&h=\(size)")
        XCTAssertEqual(optimizedURL, expectedURL)
    }
}

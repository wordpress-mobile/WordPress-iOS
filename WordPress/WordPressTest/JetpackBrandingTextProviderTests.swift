import XCTest
@testable import WordPress

final class JetpackBrandingTextProviderTests: XCTestCase {

    // MARK: Private Variables

    private var remoteFeatureFlagsStore: RemoteFeatureFlagStoreMock!

    // MARK: Setup

    override func setUp() {
        remoteFeatureFlagsStore = RemoteFeatureFlagStoreMock()
    }

    // MARK: Tests

    func testDefaultText() {
        // Given
        let provider = JetpackBrandingTextProvider(featureFlagStore: remoteFeatureFlagsStore)

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Jetpack powered")
    }

}

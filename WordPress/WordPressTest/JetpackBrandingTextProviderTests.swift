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

    func testNormalPhaseText() {
        // Given
        let provider = JetpackBrandingTextProvider(featureFlagStore: remoteFeatureFlagsStore)

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Jetpack powered")
    }

    func testPhaseOneText() {
        // Given
        let provider = JetpackBrandingTextProvider(featureFlagStore: remoteFeatureFlagsStore)
        remoteFeatureFlagsStore.removalPhaseOne = true

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Jetpack powered")
    }

    func testPhaseTwoText() {
        // Given
        let provider = JetpackBrandingTextProvider(featureFlagStore: remoteFeatureFlagsStore)
        remoteFeatureFlagsStore.removalPhaseTwo = true

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Get the Jetpack app")
    }

    func testDefaultText() {
        // Given
        let provider = JetpackBrandingTextProvider(featureFlagStore: remoteFeatureFlagsStore)
        remoteFeatureFlagsStore.removalPhaseFour = true

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Jetpack powered")
    }

}

import XCTest
@testable import WordPress

final class JetpackBrandingTextProviderTests: XCTestCase {

    func testDefaultText() {
        // Given
        let provider = JetpackBrandingTextProvider()

        // When
        let text = provider.brandingText()

        // Then
        XCTAssertEqual(text, "Jetpack powered")
    }

}

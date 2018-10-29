
import XCTest
@testable import WordPress

class WPRichContentViewTests: XCTestCase {
    /// Exercises https://github.com/wordpress-mobile/WordPress-iOS/issues/10330
    func test_ContentView_DoesNotCrash_WithEmptyString() {
        // Given
        let contentView = WPRichContentView()

        // When
        contentView.content = ""

        // Then : no assertions - the test suite crashes with an empty string
    }

    func test_ContentView_DoesNotCrash_WithSingleCharacterString() {
        // Given
        let contentView = WPRichContentView()

        // When
        contentView.content = "-"

        // Then : no assertions - the test suite should not crash
    }
}

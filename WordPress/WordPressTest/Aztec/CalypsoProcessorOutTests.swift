import XCTest
@testable import WordPress


// MARK: - CalypsoProcessorOutTests
//
class CalypsoProcessorOutTests: XCTestCase {

    let processor = CalypsoProcessorOut()

    /// Verifies that strings containing emoji characters do not result in data loss.
    ///
    /// Reference: https://github.com/wordpress-mobile/AztecEditor-iOS/issues/885
    ///
    /// Input:
    ///     - "Test &amp; Test 😊<br> lalalalala"
    ///
    /// Expected Output:
    ///     - "Test &amp; Test 😊\nlalalalala"
    ///
    func testStringsWithEmojiDoNotResultInDataLoss() {
        let input = "Test &amp; Test 😊<br> lalalalala"
        let expected = "Test &amp; Test 😊\nlalalalala"
        let output = processor.process(input)

        XCTAssertEqual(output, expected)
    }
}

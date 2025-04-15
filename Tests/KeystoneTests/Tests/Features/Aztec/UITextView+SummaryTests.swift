import XCTest

@testable import Aztec
@testable import WordPress

final class UITextView_SummaryTests: XCTestCase {

    func testTextView_10343_ReturnsCorrectCharacterCount() {
        // Given
        let textView = Aztec.TextView(defaultFont: .systemFont(ofSize: 10), defaultMissingImage: UIImage())
        let value = "Test\n\u{fffc}\n"
        textView.insertText(value)

        // When
        let actualCharacterCount = textView.characterCount

        // Then
        let expectedCharacterCount = 4
        XCTAssertEqual(actualCharacterCount, expectedCharacterCount)
    }

    func testTextView_10343_ReturnsCorrectWordCount() {
        // Given
        let textView = Aztec.TextView(defaultFont: .systemFont(ofSize: 10), defaultMissingImage: UIImage())
        let value = "Test\n\u{fffc}\n"
        textView.insertText(value)

        // When
        let actualWordCount = Int(textView.wordCount)

        // Then
        let expectedWordCount = 1
        XCTAssertEqual(actualWordCount, expectedWordCount)
    }

    func testTextView_TwoWords_ReturnsCorrectCharacterCount() {
        // Given
        let textView = Aztec.TextView(defaultFont: .systemFont(ofSize: 10), defaultMissingImage: UIImage())
        let value = "Test\n\u{fffc}\ndog"
        textView.insertText(value)

        // When
        let actualCharacterCount = textView.characterCount

        // Then
        let expectedCharacterCount = 7
        XCTAssertEqual(actualCharacterCount, expectedCharacterCount)
    }

    func testTextView_TwoWords_ReturnsCorrectWordCount() {
        // Given
        let textView = Aztec.TextView(defaultFont: .systemFont(ofSize: 10), defaultMissingImage: UIImage())
        let value = "Test\n\u{fffc}\ndog"
        textView.insertText(value)

        // When
        let actualWordCount = Int(textView.wordCount)

        // Then
        let expectedWordCount = 2
        XCTAssertEqual(actualWordCount, expectedWordCount)
    }

    func testTextView_EmptyString_ReturnsCorrectCharacterCount() {
        // Given
        let textView = Aztec.TextView(defaultFont: .systemFont(ofSize: 10), defaultMissingImage: UIImage())
        let value = ""
        textView.insertText(value)

        // When
        let actualCharacterCount = textView.characterCount

        // Then
        let expectedCharacterCount = 0
        XCTAssertEqual(actualCharacterCount, expectedCharacterCount)
    }

    func testTextView_EmptyString_ReturnsCorrectWordCount() {
        // Given
        let textView = Aztec.TextView(defaultFont: .systemFont(ofSize: 10), defaultMissingImage: UIImage())
        let value = ""
        textView.insertText(value)

        // When
        let actualWordCount = Int(textView.wordCount)

        // Then
        let expectedWordCount = 0
        XCTAssertEqual(actualWordCount, expectedWordCount)
    }
}

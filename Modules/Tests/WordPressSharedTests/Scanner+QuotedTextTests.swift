import Foundation
import Testing
import WordPressShared

// MARK: - Scanner+QuotedTextTests
//
struct ScannerTests {

    @Test func testScannerCorrectlyReturnsSingleQuotes() {
        // Given
        let inputString = #"Lorem "ipsum" dolor sit amet elit"#

        // When
        let scanner = Scanner(string: inputString)
        let quotes = scanner.scanQuotedText()

        // Then
        #expect(quotes == ["ipsum"])
    }

    @Test func testScannerCorrectlyReturnsMultipleQuotes() {
        // Given
        let inputString = #"Lorem "ipsum" dolor sit "amet" elit"#

        // When
        let scanner = Scanner(string: inputString)
        let quotes = scanner.scanQuotedText()

        // Then
        #expect(quotes == ["ipsum", "amet"])
    }

    @Test func testScannerReturnsOnlyClosedQuotes() {
        // Given
        let inputString = #""Lorem" ipsum dolor sit "amet elit"#

        // When
        let scanner = Scanner(string: inputString)
        let quotes = scanner.scanQuotedText()

        // Then
        #expect(quotes == ["Lorem"])
    }

    @Test func testScannerReturnsOnlyNonEmptyQuotes() {
        // Given
        let inputString = #"Lorem "ipsum" "" dolor "sit" """"amet "elit""#

        // When
        let scanner = Scanner(string: inputString)
        let quotes = scanner.scanQuotedText()

        // Then
        #expect(quotes == ["ipsum", "sit", "elit"])
    }

    @Test func testScannerReturnsEmptyArrayForNoResults() {
        // Given
        let inputString = #"Lorem ipsum dolor sit amet elit"#

        // When
        let scanner = Scanner(string: inputString)
        let quotes = scanner.scanQuotedText()

        // Then
        #expect(quotes == [])
    }
}

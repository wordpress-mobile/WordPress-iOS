import Foundation


// MARK: - Scanner+QuotedTextTests
//
class ScannerTests: XCTestCase {

    func testScannerCorrectlyReturnsSingleQuotes() {
        // Given
        let inputString = #"Lorem "ipsum" dolor sit amet elit"#

        // When
        let scanner = Scanner(string: inputString)
        let quotes = scanner.scanQuotedText()

        // Then
        XCTAssertEqual(quotes, ["ipsum"])
    }

    func testScannerCorrectlyReturnsMultipleQuotes() {
        // Given
        let inputString = #"Lorem "ipsum" dolor sit "amet" elit"#

        // When
        let scanner = Scanner(string: inputString)
        let quotes = scanner.scanQuotedText()

        // Then
        XCTAssertEqual(quotes, ["ipsum", "amet"])
    }

    func testScannerReturnsOnlyClosedQuotes() {
        // Given
        let inputString = #""Lorem" ipsum dolor sit "amet elit"#

        // When
        let scanner = Scanner(string: inputString)
        let quotes = scanner.scanQuotedText()

        // Then
        XCTAssertEqual(quotes, ["Lorem"])
    }

    func testScannerReturnsOnlyNonEmptyQuotes() {
        // Given
        let inputString = #"Lorem "ipsum" "" dolor "sit" """"amet "elit""#

        // When
        let scanner = Scanner(string: inputString)
        let quotes = scanner.scanQuotedText()

        // Then
        XCTAssertEqual(quotes, ["ipsum", "sit", "elit"])
    }

    func testScannerReturnsEmptyArrayForNoResults() {
        // Given
        let inputString = #"Lorem ipsum dolor sit amet elit"#

        // When
        let scanner = Scanner(string: inputString)
        let quotes = scanner.scanQuotedText()

        // Then
        XCTAssertEqual(quotes, [])
    }
}

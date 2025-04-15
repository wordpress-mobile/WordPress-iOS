import XCTest

@testable import WordPress

class PostSearchViewModelTests: XCTestCase {
    func testThatAdjacentRangesAreCollapsed() throws {
        // GIVEN
        let string = NSMutableAttributedString(string: "one two xxxxx one")

        // WHEN
        PostSearchViewModel.highlight(terms: ["one", "two"], in: string)

        // THEN
        XCTAssertTrue(string.hasAttribute(.backgroundColor, in: NSRange(location: 0, length: 7)))
        XCTAssertFalse(string.hasAttribute(.backgroundColor, in: NSRange(location: 7, length: 7)))
        XCTAssertTrue(string.hasAttribute(.backgroundColor, in: NSRange(location: 14, length: 3)))
    }

    func testThatCaseIsIgnored() {
        // GIVEN
        let string = NSMutableAttributedString(string: "One xxxxx óne")

        // WHEN
        PostSearchViewModel.highlight(terms: ["one"], in: string)

        // THEN
        XCTAssertTrue(string.hasAttribute(.backgroundColor, in: NSRange(location: 0, length: 3)))
        XCTAssertFalse(string.hasAttribute(.backgroundColor, in: NSRange(location: 3, length: 7)))
        XCTAssertTrue(string.hasAttribute(.backgroundColor, in: NSRange(location: 10, length: 3)))
    }
}

private extension NSAttributedString {
    func hasAttribute(_ attribute: NSAttributedString.Key, in range: NSRange) -> Bool {
        var effectiveRange: NSRange = .init()
        let attributes = self.attributes(at: range.location, effectiveRange: &effectiveRange)
        return attributes[attribute] != nil && effectiveRange == range
    }
}

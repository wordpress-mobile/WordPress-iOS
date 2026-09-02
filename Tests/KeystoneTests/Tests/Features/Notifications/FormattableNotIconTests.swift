import XCTest
@testable import WordPress
@testable import FormattableContentKit

final class FormattableNotIconTests: XCTestCase {

    private var subject: FormattableNoticonRange?

    private struct Constants {
        static let kind = FormattableRangeKind("noticon")
        static let icon = "🦄"
        static let range = NSRange(location: 32, length: 41)
    }

    override func setUp() {
        super.setUp()
        subject = FormattableNoticonRange(value: Constants.icon, range: Constants.range)
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testKindIsNotMutated() {
        XCTAssertEqual(subject?.kind, Constants.kind)
    }

    func testRangeIsNotMutated() {
        XCTAssertEqual(subject?.range, Constants.range)
    }

    func testNoticonReturnsExpectedValue() {
        XCTAssertEqual(subject?.value, Constants.icon)
    }

    // MARK: - apply(_:to:withShift:)

    func testApplyReturnsUTF16ShiftForMultiByteNoticon() {
        // 👨‍👩‍👧‍👦 is 1 grapheme cluster but 11 UTF-16 code units.
        // The noticon string is value + " ", so 12 UTF-16 code units total.
        // With the old .count code, the shift would have been 2 (1 emoji + 1 space).
        let familyEmoji = "👨‍👩‍👧‍👦"
        let noticonRange = FormattableNoticonRange(value: familyEmoji, range: NSRange(location: 0, length: 0))

        let baseText = "Hello World"
        let string = NSMutableAttributedString(string: baseText)

        let styles = SnippetsContentStyles(rangeStylesMap: [
            .noticon: [.foregroundColor: UIColor.red]
        ])

        let shift = noticonRange.apply(styles, to: string, withShift: 0)

        // The noticon is familyEmoji + " " = 12 UTF-16 code units
        let expectedShift = (familyEmoji + " ").utf16.count
        XCTAssertEqual(shift, expectedShift, "Shift should equal the UTF-16 count of the noticon, not the grapheme cluster count")

        // Verify styles were applied to the full noticon range
        var effectiveRange = NSRange()
        let color = string.attribute(.foregroundColor, at: 0, effectiveRange: &effectiveRange)
        XCTAssertNotNil(color)
        XCTAssertEqual(effectiveRange.length, expectedShift, "Style should cover the full UTF-16 range of the inserted noticon")
    }

    private func mockProperties() -> NotificationContentRange.Properties {
        return NotificationContentRange.Properties(range: Constants.range)
    }
}

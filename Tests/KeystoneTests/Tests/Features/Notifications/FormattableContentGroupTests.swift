import XCTest
@testable import WordPress
@testable import FormattableContentKit

final class FormattableContentGroupTests: CoreDataTestCase {
    private var subject: FormattableContentGroup?
    private var utility: NotificationUtility!

    private struct Constants {
        static let kind: FormattableContentGroup.Kind = .activity
    }

    override func setUpWithError() throws {
        utility = NotificationUtility(coreDataStack: contextManager)
        subject = FormattableContentGroup(blocks: [try mockContent()], kind: Constants.kind)
    }

    override func tearDown() {
        subject = nil
        utility = nil
    }

    func testKindRemainsAsInitialised() {
        XCTAssertEqual(subject?.kind, Constants.kind)
    }

    func testBlocksRemainAsInitialised() throws {
        let groupBlocks = subject?.blocks as? [FormattableTextContent]
        let mockBlocks = [try mockContent()]

        /// Compare by the blocks' text
        let groupBlocksText = groupBlocks!.map { $0.text }
        let mockBlocksText = mockBlocks.map { $0.text }

        XCTAssertEqual(groupBlocksText, mockBlocksText)
    }

    func testBlockOfKindReturnsExpectation() throws {
        let obtainedBlock: FormattableTextContent? = subject?.blockOfKind(.text)
        let obtainedBlockText = obtainedBlock?.text

        let mockText = try mockContent().text

        XCTAssertEqual(obtainedBlockText, mockText)
    }

    func testBlockOfKindReturnsNilWhenNotFound() {
        let obtainedBlock: FormattableTextContent? = subject?.blockOfKind(.image)

        XCTAssertNil(obtainedBlock)
    }

    // MARK: - pingbackReadMoreGroup

    func testPingbackReadMoreGroupLinkRangeCoversFullText() {
        let url = URL(string: "https://example.com")!
        let group = BodyContentGroup.pingbackReadMoreGroup(for: url)
        let block = group.blocks.first as! FormattableTextContent
        let text = block.text!

        // Find the link range (the NotificationContentRange with kind .link)
        let linkRange = block.ranges.first { $0.kind == .link }!

        // The range must cover the full string using UTF-16 counts,
        // which is what NSAttributedString expects.
        XCTAssertEqual(linkRange.range.location, 0)
        XCTAssertEqual(linkRange.range.length, text.utf16.count)
    }

    /// Regression test: building a full-text link range with `String.count`
    /// instead of `String.utf16.count` produces the wrong NSRange when the
    /// text contains multi-byte characters (e.g. emoji). The range must use
    /// UTF-16 counts because NSAttributedString is backed by UTF-16.
    func testFullTextLinkRangeWithEmojiUsesUTF16Count() {
        // 👨‍👩‍👧‍👦 is 1 grapheme cluster but 11 UTF-16 code units.
        let text = "👨‍👩‍👧‍👦 ソースの投稿を読む"
        let url = URL(string: "https://example.com")!

        let textRange = NSRange(location: 0, length: text.utf16.count)
        var properties = NotificationContentRange.Properties(range: textRange)
        properties.url = url

        let linkRange = NotificationContentRange(kind: .link, properties: properties)

        // The range must match NSAttributedString's length (UTF-16 based)
        let attributed = NSMutableAttributedString(string: text)
        XCTAssertEqual(linkRange.range.length, attributed.length,
                       "Link range length should equal NSAttributedString.length (UTF-16)")

        // Applying the range to an attributed string must not crash
        attributed.addAttribute(.link, value: url, range: linkRange.range)

        // Verify the link covers the full string
        var effectiveRange = NSRange()
        let value = attributed.attribute(.link, at: 0, effectiveRange: &effectiveRange)
        XCTAssertNotNil(value)
        XCTAssertEqual(effectiveRange.length, attributed.length)
    }

    private func mockContent() throws -> FormattableTextContent {
        let text = try mockActivity()["text"] as? String ?? ""
        return FormattableTextContent(text: text, ranges: [], actions: [])
    }

    private func mockActivity() throws -> JSONObject {
        return try JSONObject(fromFileNamed: "activity-log-activity-content.json")
    }
}

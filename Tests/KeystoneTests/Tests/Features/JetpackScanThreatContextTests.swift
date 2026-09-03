import XCTest
@testable import WordPressKit
@testable import WordPress

final class JetpackScanThreatContextTests: XCTestCase {

    private let config = JetpackThreatContext.JetpackThreatContextRendererConfig(
        numberAttributes: [.foregroundColor: UIColor.gray],
        highlightedNumberAttributes: [.foregroundColor: UIColor.red],
        contentsAttributes: [.foregroundColor: UIColor.label],
        highlightedContentsAttributes: [.foregroundColor: UIColor.label],
        highlightedSectionAttributes: [.backgroundColor: UIColor.yellow]
    )

    /// Regression test: file contents with multi-byte characters (emoji, CJK)
    /// should not crash or produce incorrect attributed strings.
    /// Previously, `String.count` was used instead of `String.utf16.count`
    /// for NSRange construction, which could produce out-of-bounds ranges.
    func testAttributedStringWithMultiByteContents() {
        let lines: [JetpackThreatContext.ThreatContextLine] = [
            .init(lineNumber: 1, contents: "<?php // 👨‍👩‍👧‍👦 emoji test", highlights: nil),
            .init(lineNumber: 2, contents: "echo '日本語テスト';", highlights: nil),
        ]

        let context = JetpackThreatContext(with: lines)
        let attributed = context.attributedString(with: config)

        XCTAssertNotNil(attributed, "Should produce a valid attributed string")

        // Verify the attributed string contains both lines' content
        let fullText = attributed!.string
        XCTAssertTrue(fullText.contains("👨‍👩‍👧‍👦"), "Should contain emoji")
        XCTAssertTrue(fullText.contains("日本語テスト"), "Should contain CJK text")
    }

    /// Verify that highlighted lines with multi-byte content don't crash.
    func testAttributedStringWithMultiByteHighlightedContents() {
        let lines: [JetpackThreatContext.ThreatContextLine] = [
            .init(lineNumber: 1, contents: "<?php // 👨‍👩‍👧‍👦 emoji", highlights: nil),
            .init(lineNumber: 2, contents: "eval('malicious');", highlights: [NSRange(location: 0, length: 4)]),
        ]

        let context = JetpackThreatContext(with: lines)
        let attributed = context.attributedString(with: config)

        XCTAssertNotNil(attributed, "Should produce a valid attributed string with highlights")
    }
}

import Testing
import UIKit

@testable import WordPressUI

struct NSMutableAttributedStringHelpersTests {

    // MARK: - applyAttribute(_:value:)

    @Test("applyAttribute covers the full string including emoji")
    func applyAttributeWithEmoji() {
        // 👨‍👩‍👧‍👦 is 1 grapheme cluster but 11 UTF-16 code units
        let string = NSMutableAttributedString(string: "Hello 👨‍👩‍👧‍👦 World")
        string.addAttribute(.foregroundColor, value: UIColor.red)

        var effectiveRange = NSRange()
        let value = string.attribute(.foregroundColor, at: 0, effectiveRange: &effectiveRange)

        #expect(value != nil)
        #expect(effectiveRange.location == 0)
        #expect(effectiveRange.length == string.length)
    }

    // MARK: - applyAttributes(_:)

    @Test("applyAttributes covers the full string including emoji")
    func applyAttributesWithEmoji() {
        let string = NSMutableAttributedString(string: "👨‍👩‍👧‍👦👨‍👩‍👧‍👦 テスト")
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.blue,
            .font: UIFont.systemFont(ofSize: 14)
        ]
        string.addAttributes(attrs)

        var colorRange = NSRange()
        let color = string.attribute(.foregroundColor, at: 0, effectiveRange: &colorRange)

        var fontRange = NSRange()
        let font = string.attribute(.font, at: 0, effectiveRange: &fontRange)

        #expect(color != nil)
        #expect(colorRange.length == string.length)
        #expect(font != nil)
        #expect(fontRange.length == string.length)
    }

    // MARK: - applyForegroundColor(_:)

    @Test("applyForegroundColor covers the full string including emoji")
    func applyForegroundColorWithEmoji() {
        let string = NSMutableAttributedString(string: "🌍 Hello 🌍")
        string.addForegroundColor(.green)

        var effectiveRange = NSRange()
        let value = string.attribute(.foregroundColor, at: 0, effectiveRange: &effectiveRange)

        #expect(value as? UIColor == .green)
        #expect(effectiveRange.length == string.length)
    }
}

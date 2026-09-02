import Testing
import Foundation

@testable import WordPressShared

struct StringRangeConversionTests {

    // MARK: - nsRange(from range: Range<String.Index>) -> NSRange

    @Test("nsRange(from:) produces correct UTF-16 NSRange for ASCII strings")
    func nsRangeFromSwiftRangeASCII() {
        let string = "Hello, world!"
        let swiftRange = string.range(of: "world")!
        let nsRange = string.nsRange(from: swiftRange)
        #expect(nsRange.location == 7)
        #expect(nsRange.length == 5)
    }

    @Test("nsRange(from:) produces correct UTF-16 NSRange with emoji")
    func nsRangeFromSwiftRangeWithEmoji() {
        // 👨‍👩‍👧‍👦 is 1 grapheme cluster but 11 UTF-16 code units
        let string = "👨‍👩‍👧‍👦 Hello"
        let swiftRange = string.range(of: "Hello")!
        let nsRange = string.nsRange(from: swiftRange)
        // "Hello" starts at UTF-16 offset 12 (11 for emoji + 1 for space)
        #expect(nsRange.location == 12)
        #expect(nsRange.length == 5)
    }

    @Test("nsRange(from:) result works correctly with NSAttributedString")
    func nsRangeFromSwiftRangeWorksWithAttributedString() {
        let string = "👨‍👩‍👧‍👦 Bold text"
        let swiftRange = string.range(of: "Bold")!
        let nsRange = string.nsRange(from: swiftRange)
        let attributed = NSMutableAttributedString(string: string)
        // This should not crash — if nsRange used grapheme offsets, this would
        // produce an out-of-bounds range for NSAttributedString
        let marker = NSAttributedString.Key("StringRangeConversionTests.marker")
        attributed.addAttribute(marker, value: true, range: nsRange)
        let attrs = attributed.attributes(at: nsRange.location, effectiveRange: nil)
        #expect(attrs[marker] != nil)
    }

    // MARK: - nsRange(of:) -> NSRange?

    @Test("nsRange(of:) produces correct UTF-16 NSRange for substring after emoji")
    func nsRangeOfSubstringAfterEmoji() {
        let string = "👨‍👩‍👧‍👦 world"
        let nsRange = string.nsRange(of: "world")
        #expect(nsRange != nil)
        #expect(nsRange!.location == 12) // 11 for emoji + 1 for space
        #expect(nsRange!.length == 5)
    }

    @Test("nsRange(of:) result can be used with NSRegularExpression range")
    func nsRangeOfWorksWithRegex() {
        let string = "🎉 test@example.com"
        // Find "test@example.com" via nsRange(of:) and verify it matches UTF-16 offsets
        let nsRange = string.nsRange(of: "test@example.com")!
        let nsString = string as NSString
        let extracted = nsString.substring(with: nsRange)
        #expect(extracted == "test@example.com")
    }
}

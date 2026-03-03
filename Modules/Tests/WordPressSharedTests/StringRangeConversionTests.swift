import Testing
import Foundation

@testable import WordPressShared

struct StringRangeConversionTests {

    // MARK: - range(from nsRange: NSRange) -> Range<String.Index>

    @Test("range(from:) converts NSRange correctly for ASCII strings")
    func rangeFromNSRangeASCII() {
        let string = "Hello, world!"
        let nsRange = NSRange(location: 7, length: 5)
        let range = string.range(from: nsRange)
        #expect(String(string[range]) == "world")
    }

    @Test("range(from:) converts NSRange correctly for strings with emoji")
    func rangeFromNSRangeWithEmoji() {
        // 👨‍👩‍👧‍👦 is 1 grapheme cluster but 11 UTF-16 code units
        let string = "👨‍👩‍👧‍👦 Hello"
        let nsRange = NSRange(location: 12, length: 5) // UTF-16 offset past emoji + space
        let range = string.range(from: nsRange)
        #expect(String(string[range]) == "Hello")
    }

    @Test("range(from:) handles multi-byte characters in the middle")
    func rangeFromNSRangeWithEmojiInMiddle() {
        // "AB👨‍👩‍👧‍👦CD" — 'A'=1, 'B'=1, emoji=11, 'C'=1, 'D'=1 UTF-16 units
        let string = "AB👨‍👩‍👧‍👦CD"
        let nsRange = NSRange(location: 13, length: 2) // "CD"
        let range = string.range(from: nsRange)
        #expect(String(string[range]) == "CD")
    }

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

    // MARK: - endOfStringNSRange()

    @Test("endOfStringNSRange() uses UTF-16 count for emoji strings")
    func endOfStringNSRangeWithEmoji() {
        // 👨‍👩‍👧‍👦 is 1 grapheme cluster but 11 UTF-16 code units
        let string = "👨‍👩‍👧‍👦"
        let nsRange = string.endOfStringNSRange()
        #expect(nsRange.location == 11) // UTF-16 count, not grapheme count (1)
        #expect(nsRange.length == 0)
    }

    @Test("endOfStringNSRange() is consistent with NSString length")
    func endOfStringNSRangeConsistentWithNSString() {
        let string = "Hello 🌍 World 👨‍👩‍👧‍👦!"
        let nsRange = string.endOfStringNSRange()
        let nsString = string as NSString
        #expect(nsRange.location == nsString.length)
    }

    // MARK: - Round-trip consistency

    @Test("NSRange → Range → NSRange round-trip preserves values with emoji")
    func roundTripWithEmoji() {
        let string = "👨‍👩‍👧‍👦 Hello 🌍 World"
        let original = NSRange(location: 12, length: 5) // "Hello"
        let swiftRange = string.range(from: original)
        let roundTripped = string.nsRange(from: swiftRange)
        #expect(roundTripped.location == original.location)
        #expect(roundTripped.length == original.length)
    }
}

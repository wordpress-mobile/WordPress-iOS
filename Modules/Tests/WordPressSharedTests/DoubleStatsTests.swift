import Foundation
import Testing
@testable import WordPressShared

// The golden strings below are en_US-shaped ("9,999", "1.2M"); the formatters follow the
// current locale, so skip rather than fail on a machine with different separators.
@Suite(
    .enabled(
        if: Locale.current.decimalSeparator == "." && Locale.current.groupingSeparator == ",",
        "Golden strings assume en_US number separators"
    )
)
struct DoubleStatsTests {

    // Golden strings guard `abbreviatedString` against regressions from the shared
    // helper refactor, and pin the spoken `abbreviatedAccessibilityLabel` output.

    @Test func abbreviatedStringIsUnchanged() {
        #expect(0.abbreviatedString() == "0")
        #expect(999.abbreviatedString() == "999")
        #expect(9999.abbreviatedString() == "9,999")
        #expect(10000.abbreviatedString() == "10.0K")
        #expect(1234324.abbreviatedString() == "1.2M")
        #expect((-1234324).abbreviatedString() == "-1.2M")
    }

    // Values that round up to the next unit take the `units[exp]` branch, distinct
    // from the ordinary `units[exp - 1]` path above.
    @Test func abbreviatedStringRoundsUpToNextUnit() {
        #expect(999999.abbreviatedString() == "1.0M")
        #expect(999999999.abbreviatedString() == "1.0B")
    }

    @Test func abbreviatedStringHeroLimit() {
        #expect(99999.abbreviatedString(forHeroNumber: true) == "99,999")
        #expect(100000.abbreviatedString(forHeroNumber: true) == "100.0K")
    }

    @Test func accessibilityLabelBelowLimitIsTheFullNumber() {
        #expect(0.abbreviatedAccessibilityLabel() == "0")
        #expect(999.abbreviatedAccessibilityLabel() == "999")
        #expect(9999.abbreviatedAccessibilityLabel() == "9,999")
        #expect(99999.abbreviatedAccessibilityLabel(forHeroNumber: true) == "99,999")
    }

    @Test func accessibilityLabelAboveLimitSpellsOutTheUnit() {
        #expect(1234324.abbreviatedAccessibilityLabel() == "1.2 million")
        #expect((-1234324).abbreviatedAccessibilityLabel() == "-1.2 million")
    }

    // The displayed "10.0K" keeps its fraction, but VoiceOver shouldn't read "ten point zero thousand".
    @Test func accessibilityLabelDropsTrailingZeroFraction() {
        #expect(10000.abbreviatedAccessibilityLabel() == "10 thousand")
        #expect(100000.abbreviatedAccessibilityLabel(forHeroNumber: true) == "100 thousand")
        #expect((-10000).abbreviatedAccessibilityLabel() == "-10 thousand")
    }

    @Test func accessibilityLabelRoundsUpToNextUnit() {
        #expect(999999.abbreviatedAccessibilityLabel() == "1 million")
        #expect(999999999.abbreviatedAccessibilityLabel() == "1 billion")
    }

    @Test(arguments: [0, 9999, 10000, 987654, 999999, 1234324, -1234324])
    func abbreviatedMatchesTheSingleValueAPIs(value: Int) {
        let abbreviated = value.abbreviated(forHeroNumber: false)
        #expect(abbreviated.text == value.abbreviatedString())
        #expect(abbreviated.accessibilityLabel == value.abbreviatedAccessibilityLabel())
    }

    @Test func largestUnitIsStillAbbreviated() {
        #expect(1e20.abbreviatedString() == "100.0E")
        #expect(1e20.abbreviatedAccessibilityLabel() == "100 quintillion")
    }

    // Past the last unit (or rounding up into it) there's no abbreviation; this used to index
    // past the end of `units` and crash.
    @Test(arguments: [1e21, 999.96e18, -1e21])
    func valuesBeyondTheLargestUnitFallBackToTheFullNumber(value: Double) {
        let abbreviated = value.abbreviated()
        #expect(abbreviated.text == abbreviated.accessibilityLabel)
        #expect(abbreviated.text.contains(","))
    }

    // `Int(log10(_:))` traps on non-finite input.
    @Test(arguments: [Double.nan, .infinity, -.infinity])
    func nonFiniteValuesDoNotCrash(value: Double) {
        let abbreviated = value.abbreviated()
        #expect(abbreviated.text == abbreviated.accessibilityLabel)
    }
}

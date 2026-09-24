import Testing
@testable import WordPressShared

struct DoubleStatsTests {

    // Golden strings guard `abbreviatedString` against regressions from the shared
    // helper refactor, and pin the spoken `abbreviatedAccessibilityLabel` output.
    // Formatting is en_US (the CI locale).

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
        #expect(10000.abbreviatedAccessibilityLabel() == "10.0 thousand")
        #expect(1234324.abbreviatedAccessibilityLabel() == "1.2 million")
        #expect((-1234324).abbreviatedAccessibilityLabel() == "-1.2 million")
        #expect(100000.abbreviatedAccessibilityLabel(forHeroNumber: true) == "100.0 thousand")
    }

    @Test func accessibilityLabelRoundsUpToNextUnit() {
        #expect(999999.abbreviatedAccessibilityLabel() == "1.0 million")
        #expect(999999999.abbreviatedAccessibilityLabel() == "1.0 billion")
    }
}

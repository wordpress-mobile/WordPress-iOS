import Foundation
import Testing
@testable import WordPressShared

struct NSDateHelperTest {
    struct Data {
        let year: Int
        let month: Int
        let day: Int

        var dateString: String {
            return "\(year)-\(month)-\(day)"
        }
    }

    let data = Data(year: 2019, month: 02, day: 17)
    var date: Date?
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    init() {
        NSTimeZone.default = TimeZone(secondsFromGMT: 0)!
        date = dateFormatter.date(from: data.dateString)
    }

    @Test func testDateAndTimeComponents() {
        #expect(date != nil)

        let components = date!.dateAndTimeComponents()
        #expect(components.year == data.year)
        #expect(components.month == data.month)
        #expect(components.day == data.day)
    }

    /// Verifies that `mediumString` produces relative format strings when less than 7 days have elapsed.
    /// If this test is failing, check that the Test Plan is still using en-US as its language
    @Test func testToMediumStringRelativeString() {
        let date = Date()

        #expect(date.toMediumString() == "now")

        #expect(date.addingTimeInterval(-60 * 5).toMediumString() == "5 minutes ago")
        #expect(date.addingTimeInterval(1).addingTimeInterval(60 * 5).toMediumString() == "in 5 minutes")

        #expect(date.addingTimeInterval(-60 * 60 * 2).toMediumString() == "2 hours ago")
        #expect(date.addingTimeInterval(1).addingTimeInterval(60 * 60 * 2).toMediumString() == "in 2 hours")

        #expect(date.addingTimeInterval(-60 * 60 * 24).toMediumString() == "yesterday")
        #expect(date.addingTimeInterval(1).addingTimeInterval(60 * 60 * 24).toMediumString() == "tomorrow")

        #expect(date.addingTimeInterval(-60 * 60 * 24 * 6).toMediumString() == "6 days ago")
        #expect(date.addingTimeInterval(1).addingTimeInterval(60 * 60 * 24 * 6).toMediumString() == "in 6 days")
    }

    @Test func testToMediumStringBeginningOfSentence() {
        let date = Date()

        #expect(
            date.addingTimeInterval(-60 * 60 * 24).toMediumString(formattingContext: .beginningOfSentence)
                == "Yesterday"
        )
        #expect(
            date.addingTimeInterval(1).addingTimeInterval(60 * 5)
                .toMediumString(formattingContext: .beginningOfSentence) == "In 5 minutes"
        )
    }

    /// Only the first word is capitalized, unlike `String.capitalized`, which produced "Sep 30, 2026 At 9:56 AM".
    @Test func testMediumStringWithTimeBeginningOfSentence() throws {
        let date = try #require(
            Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 30, hour: 9, minute: 56))
        )

        let string = date.mediumStringWithTime(
            timeZone: Calendar.current.timeZone,
            formattingContext: .beginningOfSentence
        )

        #expect(string.hasPrefix("Sep 30, 2026 at 9:56"))
    }

    @Test func testMediumStringWithTimeDoesNotKeepPreviousTimeZone() {
        let date = Date()
        let expected = date.mediumStringWithTime()

        let timeZone = TimeZone(secondsFromGMT: Calendar.current.timeZone.secondsFromGMT() - (60 * 60))
        _ = date.mediumStringWithTime(timeZone: timeZone)

        #expect(date.mediumStringWithTime() == expected)
    }

    /// Verifies that  `mediumStringWithTime` takes into account the time zone adjustment
    ///
    /// This legacy test is a bit silly because it is simply testing that the code calls `DateFormatter` with the expected configuration.
    /// This was done to make the test robust against underlying changes in `DateFormatter`'s behavior.
    /// Example failure this avoids: https://buildkite.com/automattic/wordpress-shared-ios/builds/235#018ed45e-c2be-40e5-9759-6bd7c0735ce9/6-2623
    @Test func testMediumStringTimeZoneAdjust() {
        let date = Date()
        let timeZone = TimeZone(secondsFromGMT: Calendar.current.timeZone.secondsFromGMT() - (60 * 60))
        #expect(date.toMediumString(inTimeZone: timeZone) == "now")

        let timeFormatter = DateFormatter()
        timeFormatter.doesRelativeDateFormatting = true
        timeFormatter.dateStyle = .medium
        timeFormatter.timeStyle = .short
        let withoutTimeZoneAdjust = timeFormatter.string(from: date)

        #expect(date.mediumStringWithTime() == withoutTimeZoneAdjust)

        timeFormatter.timeZone = timeZone
        let withTimeZoneAdjust = timeFormatter.string(from: date)

        #expect(date.mediumStringWithTime(timeZone: timeZone) == withTimeZoneAdjust)
    }
}

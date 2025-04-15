import XCTest
@testable import WordPress

final class StatsPeriodHelperTests: XCTestCase {
    private var sut: StatsPeriodHelper!

    override func setUpWithError() throws {
        sut = StatsPeriodHelper()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func testEndOfWeekWhenMondayIsSetAsFirstWeekday() {
        // A calendar with Monday as first weekday
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2

        // Thursday
        let dateComponents = DateComponents(year: 2023, month: 02, day: 02, hour: 8, minute: 34)

        let endDate = sut.calculateEndDate(
            from: calendar.date(from: dateComponents)!,
            offsetBy: 0,
            unit: .week,
            calendar: calendar
        )

        // 2023-02-05 Sunday should be end of the week
        XCTAssertEqual(endDate?.dateAndTimeComponents().day, 5)
    }

    func testEndOfWeekWhenSundayIsSetAsFirstWeekday() {
        // A calendar with Sunday as first weekday
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 1

        // Thursday
        let dateComponents = DateComponents(year: 2023, month: 02, day: 02, hour: 8, minute: 34)

        let endDate = sut.calculateEndDate(
            from: calendar.date(from: dateComponents)!,
            offsetBy: 0,
            unit: .week,
            calendar: calendar
        )

        // 2023-02-05 Sunday should still be end of the week
        XCTAssertEqual(endDate?.dateAndTimeComponents().day, 5)
    }

    func testEndOfWeekWhenCurrentDateIsStartOfWeek() {
        // A calendar with Monday as first weekday
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2

        // Start of Monday
        let dateComponents = DateComponents(year: 2021, month: 11, day: 15, hour: 00, minute: 00)

        let endDate = sut.calculateEndDate(
            from: calendar.date(from: dateComponents)!,
            offsetBy: 0,
            unit: .week,
            calendar: calendar
        )

        // 2021-11-21 Sunday should be end of the week
        XCTAssertEqual(endDate?.dateAndTimeComponents().day, 21)
    }

    func testEndOfWeekWhenCurrentDateIsEndOfWeek() {
        // A calendar with Monday as first weekday
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2

        // End of Sunday
        let dateComponents = DateComponents(year: 2021, month: 11, day: 21, hour: 23, minute: 59)

        let endDate = sut.calculateEndDate(
            from: calendar.date(from: dateComponents)!,
            offsetBy: 0,
            unit: .week,
            calendar: calendar
        )

        // 2021-11-21 Sunday should be end of the week
        XCTAssertEqual(endDate?.dateAndTimeComponents().day, 21)
    }

    func testEndOfNextWeek() {
        // A calendar with Monday as first weekday
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2

        // Thursday
        let dateComponents = DateComponents(year: 2023, month: 02, day: 02, hour: 8, minute: 34)

        // Get end date of next week
        let endDate = sut.calculateEndDate(
            from: calendar.date(from: dateComponents)!,
            offsetBy: 1,
            unit: .week,
            calendar: calendar
        )

        // 2023-02-12
        XCTAssertEqual(endDate?.dateAndTimeComponents().month, 2)
        XCTAssertEqual(endDate?.dateAndTimeComponents().day, 12)
    }

    func testEndOfLastWeek() {
        // A calendar with Monday as first weekday
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2

        // Thursday
        let dateComponents = DateComponents(year: 2023, month: 02, day: 02, hour: 8, minute: 34)

        // Get end date of last week
        let endDate = sut.calculateEndDate(
            from: calendar.date(from: dateComponents)!,
            offsetBy: -1,
            unit: .week,
            calendar: calendar
        )

        // 2023-01-29
        XCTAssertEqual(endDate?.dateAndTimeComponents().month, 1)
        XCTAssertEqual(endDate?.dateAndTimeComponents().day, 29)
    }
}

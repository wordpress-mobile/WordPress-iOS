import XCTest
@testable import WordPress

final class StatsTrafficDatePickerViewModelTests: XCTestCase {
    private var viewModel: StatsTrafficDatePickerViewModel!
    let today = Date("2023-01-18")
    let startOfWeek = Date("2023-01-15")
    let endOfWeek = Date("2023-01-21")
    let startOfMonth = Date("2023-01-01")
    let endOfMonth = Date("2023-01-31")
    let startOfYear = Date("2023-01-01")
    let endOfYear = Date("2023-12-31")

    let yesterday = Date("2023-01-17")

    override func setUpWithError() throws {
        viewModel = StatsTrafficDatePickerViewModel(now: today)
    }

    override func tearDownWithError() throws {
        viewModel = nil
    }

    func testDefaultPeriodIsDay() throws {
        XCTAssertTrue(viewModel.selectedPeriod == .day)
    }

    func testDefaultDateInterval() throws {
        let dateInterval = viewModel.currentDateInterval
        XCTAssertEqual(today, dateInterval.start)
        XCTAssertEqual(today, dateInterval.end)
    }

    func testWeekInterval() throws {
        viewModel.selectedPeriod = .week
        let dateInterval = viewModel.currentDateInterval
        XCTAssertTrue(dateInterval.start.isSameDay(as: startOfWeek))
        XCTAssertTrue(dateInterval.end.isSameDay(as: endOfWeek))
    }

    func testMonthInterval() throws {
        viewModel.selectedPeriod = .month
        let dateInterval = viewModel.currentDateInterval
        XCTAssertTrue(dateInterval.start.isSameDay(as: startOfMonth))
        XCTAssertTrue(dateInterval.end.isSameDay(as: endOfMonth))
    }

    func testYearInterval() throws {
        viewModel.selectedPeriod = .year
        let dateInterval = viewModel.currentDateInterval
        XCTAssertTrue(dateInterval.start.isSameDay(as: startOfYear))
        XCTAssertTrue(dateInterval.end.isSameDay(as: endOfYear))
    }

    func testYesterdayInterval() throws {
        viewModel.selectedPeriod = .day
        viewModel.goToPreviousDateInterval()
        XCTAssertEqual(yesterday, viewModel.currentDateInterval.start)
        XCTAssertEqual(yesterday, viewModel.currentDateInterval.end)
    }

    func testTomorrowIntervalNotAvailable() throws {
        viewModel.selectedPeriod = .day
        XCTAssertFalse(viewModel.isNextDateIntervalAvailable)
    }

    func testStartOfWeekIsusedWhenSwitchingFromWeekToDay() throws {
        viewModel.selectedPeriod = .week
        viewModel.selectedPeriod = .day
        XCTAssertEqual(startOfWeek, viewModel.currentDateInterval.start)
        XCTAssertEqual(startOfWeek, viewModel.currentDateInterval.end)
    }

}

private extension Date {

    init(_ dateString: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        self = dateFormatter.date(from: dateString)!
    }

    func isSameDay(as date: Date) -> Bool {
        return Calendar.current.isDate(self, inSameDayAs: date)
    }
}

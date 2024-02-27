import XCTest
@testable import WordPress

final class StatsTrafficDatePickerViewModelTests: XCTestCase {
    private var viewModel: StatsTrafficDatePickerViewModel!
    let today = Date("2024-01-18")

    override func setUpWithError() throws {
        viewModel = StatsTrafficDatePickerViewModel(period: .day, date: today)
    }

    override func tearDownWithError() throws {
        viewModel = nil
    }

    func testNavigation() throws {

        let yesterday = Date("2024-01-17")
        let aWeekEarlier = Date("2024-01-10")
        let aMonthEarlier = Date("2023-12-10")

        viewModel.goToPreviousPeriod()
        XCTAssertEqual(yesterday, viewModel.date)

        viewModel.period = .week
        viewModel.goToPreviousPeriod()
        XCTAssertEqual(aWeekEarlier, viewModel.date)

        viewModel.period = .month
        viewModel.goToPreviousPeriod()
        XCTAssertEqual(aMonthEarlier, viewModel.date)
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

import XCTest
@testable import WordPress

class SchedulingCalendarViewControllerTests: XCTestCase {

    var calendarVC: SchedulingCalendarViewController?
    var navigationController: UINavigationController?

    override func setUp() {
        calendarVC = SchedulingCalendarViewController()
        navigationController = UINavigationController(rootViewController: calendarVC!)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testVCCoordinatorPassing() {
        let dateValue = Date()
        let coordinator = DateCoordinator(date: dateValue, timeZone: TimeZone(secondsFromGMT: 0)!, dateFormatter: DateFormatter(), dateTimeFormatter: DateFormatter(), updated: { _ in })
        calendarVC?.coordinator = coordinator
        calendarVC?.nextButtonPressed()

        let coordinatorDate = (navigationController?.topViewController as? DateCoordinatorHandler)?.coordinator?.date

        XCTAssertEqual(coordinatorDate, dateValue, "Passed date should be the same")
    }

    /// Tests that the hours and minutes are retained even with a date change
    func testVCCoordinatorComponents() {
        let dateValue = Date()
        let coordinator = DateCoordinator(date: dateValue, timeZone: TimeZone(secondsFromGMT: 0)!, dateFormatter: DateFormatter(), dateTimeFormatter: DateFormatter(), updated: { _ in })
        calendarVC?.coordinator = coordinator
        calendarVC?.calendarMonthView.updated?(dateValue.addingTimeInterval(24000))
        calendarVC?.nextButtonPressed()

        let coordinatorDate = (navigationController?.topViewController as? DateCoordinatorHandler)?.coordinator?.date

        XCTAssertNotNil(coordinatorDate, "Coordinator date should not be nil")

        let newComponents = Calendar.current.dateComponents([.hour, .minute], from: coordinatorDate!)
        let originalComponents = Calendar.current.dateComponents([.hour, .minute], from: dateValue)

        XCTAssertNotEqual(dateValue, coordinatorDate, "Dates should not be equal.")
        XCTAssertEqual(newComponents, originalComponents, "Date should retain its hours and minutes")
    }

    /// Tests that proper calendar is used based on site time zone insted of device time zone
    func testVCCoordinatorCalendar() {

        let currentDate = Date()
        let dateValue = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: currentDate)!
        let timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT(for: currentDate) - 60 * 60)!

        let coordinator = DateCoordinator(date: nil, timeZone: timeZone, dateFormatter: DateFormatter(), dateTimeFormatter: DateFormatter(), updated: { _ in })
        calendarVC?.coordinator = coordinator
        calendarVC?.calendarMonthView.updated?(dateValue)
        calendarVC?.nextButtonPressed()

        let coordinatorDate = calendarVC?.coordinator?.date

        var calendar = Calendar.current
        calendar.timeZone = timeZone

        let convertedComponents = calendar.dateComponents([.year, .month, .day], from: dateValue)
        let coordinatorComponents = calendar.dateComponents([.year, .month, .day], from: coordinatorDate!)

        XCTAssertEqual(coordinatorComponents, convertedComponents, "Date should be converted to proper day of time zone.")
    }
}

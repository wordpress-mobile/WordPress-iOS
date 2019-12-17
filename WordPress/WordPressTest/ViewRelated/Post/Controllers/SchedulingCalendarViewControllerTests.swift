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
        XCTAssertEqual(newComponents, originalComponents, "Date should retain its minutes and seconds")
    }
}

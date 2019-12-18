import XCTest
@testable import WordPress

class TimePickerViewControllerTests: XCTestCase {

    var timePickerVC: TimePickerViewController?
    var navigationController: UINavigationController?

    override func setUp() {
        timePickerVC = TimePickerViewController()
        navigationController = UINavigationController(rootViewController: timePickerVC!)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testVCCoordinatorPassing() {
        let dateValue = Date()
        let coordinator = DateCoordinator(date: dateValue, timeZone: TimeZone(secondsFromGMT: 0)!, dateFormatter: DateFormatter(), dateTimeFormatter: DateFormatter(), updated: { _ in })
        timePickerVC?.coordinator = coordinator
        timePickerVC?.timePickerChanged(0)

        let coordinatorDate = (navigationController?.topViewController as? DateCoordinatorHandler)?.coordinator?.date

        XCTAssertEqual(coordinatorDate, dateValue, "Passed date should be the same")
    }
}

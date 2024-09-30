import XCTest
@testable import WordPressAuthenticator

final class NavigationToAccountTests: XCTestCase {
    func testNavigationCommandNavigatesToExpectedDestination() {
        let origin = UIViewController()
        let navigationController = MockNavigationController(rootViewController: origin)

        let command = NavigateToEnterAccount(signInSource: .wpCom)
        command.execute(from: origin)

        let pushedViewController = navigationController.pushedViewController

        XCTAssertNotNil(pushedViewController)
        XCTAssertTrue(pushedViewController is GetStartedViewController)
    }
}

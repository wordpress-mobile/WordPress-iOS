import XCTest
@testable import WordPressAuthenticator

final class NavigationToEnterSiteTests: XCTestCase {
    func testNavigationCommandNavigatesToExpectedDestination() {
        let origin = UIViewController()
        let navigationController = MockNavigationController(rootViewController: origin)

        let command = NavigateToEnterSite()
        command.execute(from: origin)

        let pushedViewController = navigationController.pushedViewController

        XCTAssertNotNil(pushedViewController)
        XCTAssertTrue(pushedViewController is SiteAddressViewController)
    }
}

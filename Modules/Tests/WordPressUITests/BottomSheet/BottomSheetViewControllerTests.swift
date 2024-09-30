import XCTest

@testable import WordPressUI

class BottomSheetViewControllerTests: XCTestCase {

    /// - Add the given ViewController as a child View Controller
    ///
    func testAddTheGivenViewControllerAsAChildViewController() {
        let viewController = BottomSheetPresentableViewController()
        let bottomSheet = BottomSheetViewController(childViewController: viewController)

        bottomSheet.viewDidLoad()

        XCTAssertTrue(bottomSheet.children.contains(viewController))
    }

    /// - Add the given ViewController view to the subviews of the Bottom Sheet
    ///
    func testAddGivenVCViewToTheBottomSheetSubviews() {
        let viewController = BottomSheetPresentableViewController()
        let bottomSheet = BottomSheetViewController(childViewController: viewController)

        bottomSheet.viewDidLoad()

        XCTAssertTrue(bottomSheet.view.subviews.flatMap { $0.subviews }.contains(viewController.view))
    }
}

private class BottomSheetPresentableViewController: UIViewController, DrawerPresentable {
    var initialHeight: CGFloat = 0
}

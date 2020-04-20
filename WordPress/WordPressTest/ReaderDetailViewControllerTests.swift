@testable import WordPress
import XCTest

class ReaderDetailViewControllerTests: XCTestCase {

    private var readerDetailViewController: ReaderDetailViewController?

    private struct TestConstants {
        static let reblogLabel = NSLocalizedString("Reblog post", comment: "Accessibility label for the reblog button.")
    }

    override func setUp() {
        super.setUp()

        let storyboard = UIStoryboard(name: "Reader", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "ReaderDetailViewController") as? ReaderDetailViewController else {
            XCTFail("Unable to instantiate ReaderDetailViewController")
            return
        }
        self.readerDetailViewController = viewController
        // will trigger viewDidLoad()
        _ = viewController.view
    }

    override func tearDown() {
        readerDetailViewController = nil
        super.tearDown()
    }

    func testReblogButtonMatchesExpectation() {
        XCTAssertEqual(readerDetailViewController?.getReblogButtonForTesting().accessibilityLabel, TestConstants.reblogLabel, "Incorrect accessibility label: Reblog button")
    }
}

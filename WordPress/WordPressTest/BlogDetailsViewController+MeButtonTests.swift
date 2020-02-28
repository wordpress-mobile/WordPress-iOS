@testable import WordPress
import XCTest

class MockScenePresenter: ScenePresenter {
    var presentedViewController: UIViewController?
    var presentExpectation: XCTestExpectation?

    func present(on viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        guard viewController is BlogDetailsViewController else {
            XCTFail("Invalid presenting viewController")
            return
        }
        presentedViewController = UIViewController()
        presentedViewController?.accessibilityLabel = "testController"
        presentExpectation?.fulfill()
    }
}

class BlogDetailsViewControllerTests: XCTestCase {

    private var blogDetailsViewController: BlogDetailsViewController?
    private var scenePresenter: MockScenePresenter?

    private struct TestConstants {
        static let meButtonLabel = NSLocalizedString("Me", comment: "Accessibility label for the Me button in My Site.")
        static let meButtonHint = NSLocalizedString("Open the Me Section", comment: "Accessibility hint the Me button in My Site.")
    }


    override func setUp() {
        scenePresenter = MockScenePresenter()
        guard let presenter = scenePresenter else {
            XCTFail("Presenter not initialized")
            return
        }
        blogDetailsViewController = BlogDetailsViewController(meScenePresenter: presenter)
    }

    override func tearDown() {
        blogDetailsViewController = nil
        scenePresenter = nil
    }

    func testInitWithScenePresenter() {
        // Given
        guard let controller = blogDetailsViewController else {
            XCTFail("Blog details viewController not initialized")
            return
        }
        // When
        controller.addMeButtonToNavigationBar()
        // Then
        guard let meButton = controller.navigationItem.rightBarButtonItem else {
            XCTFail("Me Button not installed")
            return
        }

        XCTAssertEqual(meButton.accessibilityLabel, TestConstants.meButtonLabel)
        XCTAssertEqual(meButton.accessibilityHint, TestConstants.meButtonHint)
    }

    func testPresentMeOnButtonTap() {
        // Given
        guard let controller = blogDetailsViewController else {
            XCTFail("Blog details viewController not initialized")
            return
        }
        controller.addMeButtonToNavigationBar()
        guard controller.navigationItem.rightBarButtonItem != nil else {
            XCTFail("Me Button not installed")
            return
        }
        scenePresenter?.presentExpectation = expectation(description: "Me was presented")
        // When

        guard let target = blogDetailsViewController?.target(forAction: #selector(BlogDetailsViewController.presentHandler),
                                                             withSender: blogDetailsViewController) else {
            XCTFail("Target not found")
            return
        }

        let actionableTarget = target as AnyObject
        _ = actionableTarget.perform(#selector(BlogDetailsViewController.presentHandler))

        // Then
        guard let presentedController = scenePresenter?.presentedViewController else {
            XCTFail("Presented controller was not instantiated")
            return
        }
        XCTAssertEqual(presentedController.accessibilityLabel, "testController")
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
}


import XCTest
@testable import WordPress

class FullScreenCommentReplyViewControllerTests: XCTestCase {
    private var controller: FullScreenCommentReplyViewController!
    private var window: UIWindow!

    override func setUp() {
        controller = FullScreenCommentReplyViewController.newEdit()
        window = UIWindow()

        XCTAssertNotNil(controller)
        XCTAssertNotNil(window)

        loadView(forController: controller, inWindow: window)
    }

    override func tearDown() {
        window = nil
        controller = nil

        super.tearDown()
    }

    // MARK: - Tests

    /// Tests loading a new instance of the view controller and checking the content
    /// config property is being set correctly in the text view
    func testTextViewContentIsLoaded() {
        guard let controller = FullScreenCommentReplyViewController.newEdit() else {
            XCTFail("Controller is nil")
            return
        }


        let content = "Test Content"
        controller.content = content

        loadView(forController: controller, inWindow: UIWindow())
        XCTAssertEqual(content, controller.textView.text)

    }

    /// Tests the button state becomes correctly enabled
    /// as the `textView` content changes
    func testReplyButtonStateEnables() {
        controller.textView.text = "Test - State Enabled"
        UIView.performWithoutAnimation {
            controller.contentDidChange()
            XCTAssertTrue(controller.replyButton.isEnabled)
        }
    }

    /// Tests the button state becomes correctly disabled
    /// as the `textView` content changes
    func testReplyButtonStateDisables() {
        controller.textView.text = ""
        UIView.performWithoutAnimation {
            controller.contentDidChange()
            XCTAssertFalse(controller.replyButton.isEnabled)
        }
    }


    /// Tests the onExitFullscreen callback is correctly called when pressing the cancel button
    /// also validates the arguments being triggered are correct
    func testExitCallbackCalledWhenCancelPressed() {
        let testContent = "Test - Cancel"
        let callbackExpectation = expectation(description: "onExitFullscreen is called successfully when the cancel button is pressed")

        controller.textView.text = testContent

        controller.onExitFullscreen = { (shouldSave, content) in
            callbackExpectation.fulfill()

            XCTAssertFalse(shouldSave)
            XCTAssertEqual(content, testContent)
        }

        controller.btnExitFullscreenPressed()

        waitForExpectations(timeout: 1)
    }

    /// Tests the onExitFullscreen callback is correctly called when pressing the save button
    /// also validates the arguments being triggered are correct
    func testExitCallbackCalledWhenSavePressed() {
        let testContent = "Test - Save"
        let callbackExpectation = expectation(description: "onExitFullscreen is called successfully when the save button is pressed")

        controller.textView.text = testContent

        controller.onExitFullscreen = { (shouldSave, content) in
            callbackExpectation.fulfill()

            XCTAssertTrue(shouldSave)
            XCTAssertEqual(content, testContent)
        }

        controller.btnSavePressed()

        waitForExpectations(timeout: 1)
    }

    // MARK: - Helpers

    /// Helper method to trigger the viewDidLoad method
    /// - Parameters:
    ///   - forController: The controller whose view you want to load
    ///   - inWindow: The window instance you want to load it in
    private func loadView(forController: UIViewController, inWindow: UIWindow) {
        inWindow.addSubview(forController.view)
        RunLoop.current.run(until: Date())
    }
}

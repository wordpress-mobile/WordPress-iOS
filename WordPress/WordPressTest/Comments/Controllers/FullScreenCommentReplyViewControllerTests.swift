
import XCTest
@testable import WordPress

class FullScreenCommentReplyViewControllerTests: CoreDataTestCase {
    private var viewModel: FullScreenCommentReplyViewModelType!
    private var controller: FullScreenCommentReplyViewController!
    private var window: UIWindow!

    override func setUp() {
        viewModel = FullScreenCommentReplyViewModelMock(context: mainContext)
        controller = FullScreenCommentReplyViewController(viewModel: viewModel)

        window = UIWindow()

        XCTAssertNotNil(controller)
        XCTAssertNotNil(window)

        load(controller, inWindow: window)
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
        let content = "Test Content"
        controller = FullScreenCommentReplyViewController(viewModel: viewModel)

        controller.content = content

        load(controller, inWindow: UIWindow())
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

        controller.onExitFullscreen = { (shouldSave, content, lastSearchText) in
            callbackExpectation.fulfill()

            XCTAssertFalse(shouldSave)
            XCTAssertEqual(content, testContent)
            XCTAssertNil(lastSearchText)
        }

        controller.btnExitFullscreenPressed()

        waitForExpectations(timeout: 1)
    }

    /// Tests the onExitFullscreen callback is correctly called when pressing the cancel button
    /// also validates the arguments being triggered are correct
    // TODO: flaky test (and we'll rewrite this soon)
    func _testExitCallbackCalledWithLastSearchTextWhenCancelPressed() throws {
        let testContent = "Test - Cancel"
        let expectedLastSearchText = "@Ren"
        let callbackExpectation = expectation(description: "onExitFullscreen is called successfully when the cancel button is pressed")
        let blog = BlogBuilder(mainContext).build()
        try mainContext.save()
        controller = FullScreenCommentReplyViewController(viewModel: viewModel)
        controller.enableSuggestions(with: blog.dotComID!, prominentSuggestionsIds: [], searchText: expectedLastSearchText)
        controller.content = testContent
        load(controller, inWindow: UIWindow())

        controller.onExitFullscreen = { (shouldSave, content, lastSearchText) in
            callbackExpectation.fulfill()

            XCTAssertFalse(shouldSave)
            XCTAssertEqual(content, testContent)
            XCTAssertEqual(lastSearchText, expectedLastSearchText)
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

        controller.onExitFullscreen = { (shouldSave, content, lastSearchText) in
            callbackExpectation.fulfill()

            XCTAssertTrue(shouldSave)
            XCTAssertEqual(content, testContent)
            XCTAssertNil(lastSearchText)
        }

        controller.btnSavePressed()

        waitForExpectations(timeout: 1)
    }

    // MARK: - Helpers

    /// Helper method to trigger the viewDidLoad, viewWillAppear and viewDidAppear methods
    /// - Parameters:
    ///   - controller: The controller you want to load
    ///   - inWindow: The window instance you want to load it in
    private func load(_ controller: UIViewController, inWindow: UIWindow) {
        inWindow.addSubview(controller.view)
        inWindow.rootViewController = UINavigationController(rootViewController: controller)
        inWindow.makeKeyAndVisible()
        controller.beginAppearanceTransition(true, animated: false)
        RunLoop.current.run(until: Date())
    }
}

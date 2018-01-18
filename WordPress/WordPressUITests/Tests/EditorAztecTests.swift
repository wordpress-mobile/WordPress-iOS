import XCTest

class EditorAztecTests: XCTestCase {
    private var editorScreen: EditorScreen!

    override func setUp() {
        super.setUp()
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments = ["NoAnimations"]
        app.activate()

        editorScreen = LoginFlow
            .login(email: WPUITestCredentials.testUserEmail, password: WPUITestCredentials.testUserPassword)
            .tabBar.gotoEditorScreen()
    }

    override func tearDown() {
        editorScreen.goBack()
        LoginFlow.logoutIfNeeded()
        super.tearDown()
    }

    // Github issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/385
    func testLongTitle() {
        let longTitle = "long title in a galaxy not so far away"
        // Title heigh contains of actual textfield height + bottom line.
        // 16.5px - is the height of that bottom line. Its not changing with different font sizes
        let titleTextView = editorScreen.titleView
        let titleLineHeight = titleTextView.frame.height - 16.5
        let oneLineTitleHeight = titleTextView.frame.height

        let repeatTimes = isIPhone() ? 6 : 20
        _ = editorScreen.enterTextInTitle(text: String(repeating: "very ", count: repeatTimes) + longTitle)

        let twoLineTitleHeight = titleTextView.frame.height

        XCTAssert(twoLineTitleHeight - oneLineTitleHeight >= titleLineHeight )
    }
}

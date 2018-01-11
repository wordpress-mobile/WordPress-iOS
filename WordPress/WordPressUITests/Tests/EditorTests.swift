import XCTest

class EditorTests: XCTestCase {
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
            .tabBar
            .gotoEditorScreen()
    }

    override func tearDown() {
        _ = editorScreen.goBack()
        super.tearDown()
    }

    func testSimplePublish() {
        let longText = String(repeating: "very ", count: 20) + "long text in a galaxy not so far away"
        _ = editorScreen
            .enterTextInTitle(text: "Hello XCUI World!")
            .enterText(text: longText)
            .publish()
            .done()
            .tabBar.gotoEditorScreen()
    }
}

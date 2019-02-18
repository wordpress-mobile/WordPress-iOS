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
            .login(email: WPUITestCredentials.testWPcomUserEmail, password: WPUITestCredentials.testWPcomPassword)
            .tabBar
            .gotoEditorScreen()
    }

    override func tearDown() {
        if editorScreen.isLoaded() {
            _ = editorScreen.goBack()
        }
        LoginFlow.logoutIfNeeded()
        super.tearDown()
    }

    func testSimplePublish() {
        let title = "Hello XCUI World!"
        let longText = String(repeating: "very ", count: 20) + "long text in a galaxy not so far away"
        _ = editorScreen
            .enterTextInTitle(text: title)
            .enterText(text: longText)
            .publish()
            .viewPublishedPost(withTitle: title)
            .verifyEpilogueDisplays(postTitle: title, siteAddress: WPUITestCredentials.testWPcomSiteAddress)
            .done()
    }
}

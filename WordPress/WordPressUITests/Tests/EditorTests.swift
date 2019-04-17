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

        // Media permissions alert handler
        systemAlertHandler(alertTitle: "“WordPress” Would Like to Access Your Photos", alertButton: "OK")

        editorScreen = LoginFlow
            .loginIfNeeded(email: WPUITestCredentials.testWPcomUserEmail, password: WPUITestCredentials.testWPcomPassword)
            .gotoEditorScreen()
    }

    override func tearDown() {
        if editorScreen.isLoaded() {
            _ = editorScreen.goBack()
        }
        super.tearDown()
    }

    func testTextPostPublish() {
        let title = DataHelper.title
        let content = DataHelper.longText
        _ = editorScreen
            .enterTextInTitle(text: title)
            .enterText(text: content)
            .publish()
            .viewPublishedPost(withTitle: title)
            .verifyEpilogueDisplays(postTitle: title, siteAddress: WPUITestCredentials.testWPcomSiteAddress)
            .done()
    }

    func testBasicPostPublish() {
        let title = DataHelper.title
        let content = DataHelper.longText
        let category = DataHelper.category
        let tag = DataHelper.tag
        _ = editorScreen
            .enterTextInTitle(text: title)
            .enterText(text: content)
            .addImageByOrder(id: 0)
            .openPostSettings()
            .openCategories()
            .selectCategory(name: category)
            .goBackToSettings()
            .openTags()
            .addTag(name: tag)
            .goBackToSettings()
            .setFeaturedImage()
            .verifyPostSettings(withCategory: category, withTag: tag, hasImage: true)
            .closePostSettings()
            .publish()
            .viewPublishedPost(withTitle: title)
            .verifyEpilogueDisplays(postTitle: title, siteAddress: WPUITestCredentials.testWPcomSiteAddress)
            .done()
    }
}

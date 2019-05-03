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
            .loginIfNeeded(siteUrl: WPUITestCredentials.testWPcomSiteAddress, username: WPUITestCredentials.testWPcomUsername, password: WPUITestCredentials.testWPcomPassword)
            .gotoEditorScreen()
    }

    override func tearDown() {
        if editorScreen != nil && !TabNavComponent.isVisible() {
            EditorFlow.returnToMainEditorScreen()
            editorScreen.closeEditor()
        }
        super.tearDown()
    }

    func testTextPostPublish() {
        let title = getRandomPhrase()
        let content = getRandomContent()
        _ = editorScreen
            .enterTextInTitle(text: title)
            .enterText(text: content)
            .publish()
            .viewPublishedPost(withTitle: title)
            .verifyEpilogueDisplays(postTitle: title, siteAddress: WPUITestCredentials.testWPcomSiteAddress)
            .done()
    }

    func testBasicPostPublish() {
        let title = getRandomPhrase()
        let content = getRandomContent()
        let category = getCategory()
        let tag = getTag()
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

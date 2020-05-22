import XCTest

class EditorGutenbergTests: XCTestCase {
    private var editorScreen: BlockEditorScreen!

    override func setUp() {
        setUpTestSuite()

        _ = LoginFlow.loginIfNeeded(siteUrl: WPUITestCredentials.testWPcomSiteAddress, username: WPUITestCredentials.testWPcomUsername, password: WPUITestCredentials.testWPcomPassword)
        editorScreen = EditorFlow
            .toggleBlockEditor(to: .on)
            .goBackToMySite()
            .tabBar.gotoBlockEditorScreen()
    }

    override func tearDown() {
        takeScreenshotOfFailedTest()
        if editorScreen != nil && !TabNavComponent.isVisible() {
            EditorFlow.returnToMainEditorScreen()
            editorScreen.closeEditor()
        }
        LoginFlow.logoutIfNeeded()
        super.tearDown()
    }

    func testTextPostPublish() {
        let title = getRandomPhrase()
        let content = getRandomContent()
        editorScreen
            .dismissNotificationAlertIfNeeded(.accept)
            .enterTextInTitle(text: title)
            .addParagraphBlock(withText: content)
            .publish()
            .viewPublishedPost(withTitle: title)
            .verifyEpilogueDisplays(postTitle: title, siteAddress: WPUITestCredentials.testWPcomSitePrimaryAddress)
            .done()
    }

    func testBasicPostPublish() {
        let title = getRandomPhrase()
        let content = getRandomContent()
        let category = getCategory()
        let tag = getTag()
        editorScreen
            .dismissNotificationAlertIfNeeded(.accept)
            .enterTextInTitle(text: title)
            .addParagraphBlock(withText: content)
            .addImage()
            .openPostSettings()
            .selectCategory(name: category)
            .addTag(name: tag)
            .setFeaturedImage()
            .verifyPostSettings(withCategory: category, withTag: tag, hasImage: true)
            .removeFeatureImage()
            .verifyPostSettings(withCategory: category, withTag: tag, hasImage: false)
            .setFeaturedImage()
            .verifyPostSettings(withCategory: category, withTag: tag, hasImage: true)
            .closePostSettings()
        BlockEditorScreen().publish()
            .viewPublishedPost(withTitle: title)
            .verifyEpilogueDisplays(postTitle: title, siteAddress: WPUITestCredentials.testWPcomSitePrimaryAddress)
            .done()
    }
}

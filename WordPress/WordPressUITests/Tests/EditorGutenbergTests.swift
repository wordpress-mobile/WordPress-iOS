import XCTest

class EditorGutenbergTests: XCTestCase {
    private var editorScreen: BlockEditorScreen!

    override func setUp() {
        setUpTestSuite()

        _ = LoginFlow.loginIfNeeded(siteUrl: WPUITestCredentials.testWPcomSiteAddress, username: WPUITestCredentials.testWPcomUsername, password: WPUITestCredentials.testWPcomPassword)
        editorScreen = EditorFlow
            .toggleBlockEditor(to: .on)
            .tabBar.gotoBlockEditorScreen()
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
        editorScreen
            .enterTextInTitle(text: title)
            .addParagraphBlock(withText: content)
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
        editorScreen
            .enterTextInTitle(text: title)
            .addParagraphBlock(withText: content)
            .addImage()
            .openPostSettings()
            .selectCategory(name: category)
            .addTag(name: tag)
            .setFeaturedImage()
            .verifyPostSettings(withCategory: category, withTag: tag, hasImage: true)
            .closePostSettings()
        BlockEditorScreen().publish()
            .viewPublishedPost(withTitle: title)
            .verifyEpilogueDisplays(postTitle: title, siteAddress: WPUITestCredentials.testWPcomSiteAddress)
            .done()
    }
}

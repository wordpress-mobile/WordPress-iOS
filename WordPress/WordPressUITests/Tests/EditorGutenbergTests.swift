import UITestsFoundation
import XCTest

class EditorGutenbergTests: XCTestCase {
    private var editorScreen: BlockEditorScreen!

    override func setUpWithError() throws {
        setUpTestSuite()

        _ = try LoginFlow.loginIfNeeded(siteUrl: WPUITestCredentials.testWPcomSiteAddress, email: WPUITestCredentials.testWPcomUserEmail, password: WPUITestCredentials.testWPcomPassword)
        editorScreen = try EditorFlow
            .goToMySiteScreen()
            .tabBar.gotoBlockEditorScreen()
            .dismissNotificationAlertIfNeeded(.accept)
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()

        if editorScreen == nil {
            BlockEditorScreen.closeEditorDiscardingChanges()
        } else if TabNavComponent.isVisible() == false {
            editorScreen.dismissBlocksPickerIfNeeded()
            EditorFlow.returnToMainEditorScreen()
            editorScreen.closeEditor()
        }
        try LoginFlow.logoutIfNeeded()
        try super.tearDownWithError()
    }

    let title = "Rich post title"
    let content = "Some text, and more text"

    func testTextPostPublish() throws {

        try editorScreen
            .enterTextInTitle(text: title)
            .addParagraphBlock(withText: content)
            .verifyContentStructure(blocks: 1, words: 5, characters: 24)
            .publish()
            .viewPublishedPost(withTitle: title)
            .verifyEpilogueDisplays(postTitle: title, siteAddress: WPUITestCredentials.testWPcomSitePrimaryAddress)
            .done()
    }

    func testBasicPostPublish() throws {

        let category = getCategory()
        let tag = getTag()
        try editorScreen
            .enterTextInTitle(text: title)
            .addParagraphBlock(withText: content)
            .addImage()
            .verifyContentStructure(blocks: 2, words: 5, characters: 24)
            .openPostSettings()
            .selectCategory(name: category)
            .addTag(name: tag)
            .closePostSettings()
        try BlockEditorScreen().publish()
            .viewPublishedPost(withTitle: title)
            .verifyEpilogueDisplays(postTitle: title, siteAddress: WPUITestCredentials.testWPcomSitePrimaryAddress)
            .done()
    }

    func testAddRemoveFeaturedImage() throws {

        try editorScreen
            .enterTextInTitle(text: title)
            .addParagraphBlock(withText: content)
            .verifyContentStructure(blocks: 1, words: 5, characters: 24)
            .openPostSettings()
            .setFeaturedImage()
            .verifyPostSettings(hasImage: true)
            .removeFeatureImage()
            .verifyPostSettings(hasImage: false)
            .setFeaturedImage()
            .verifyPostSettings(hasImage: true)
            .closePostSettings()
    }

    func testAddGalleryBlock() throws {
        try editorScreen
            .enterTextInTitle(text: title)
            .addParagraphBlock(withText: content)
            .addImageGallery()
            .verifyContentStructure(blocks: 5, words: 5, characters: 24)
    }
}

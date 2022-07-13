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
        removeApp()
    }

    let title = "Rich post title"
    let content = "Some text, and more text"

    func testTextPostPublish() throws {

        try editorScreen
            .enterTextInTitle(text: title)
            .addParagraphBlock(withText: content)
            .verifyContentStructure(blocks: 1, words: content.components(separatedBy: " ").count, characters: content.count)
            .publish()
            .viewPublishedPost(withTitle: title)
            .verifyEpilogueDisplays(postTitle: title, siteAddress: WPUITestCredentials.testWPcomSitePrimaryAddress)
            .done()
    }

    func testBasicPostPublishWithCategoryAndTag() throws {

        let category = getCategory()
        let tag = getTag()
        try editorScreen
            .enterTextInTitle(text: title)
            .addParagraphBlock(withText: content)
            .addImage()
            .verifyContentStructure(blocks: 2, words: content.components(separatedBy: " ").count, characters: content.count)
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
            .verifyContentStructure(blocks: 1, words: content.components(separatedBy: " ").count, characters: content.count)
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
            .verifyContentStructure(blocks: 2, words: content.components(separatedBy: " ").count, characters: content.count)
    }
}

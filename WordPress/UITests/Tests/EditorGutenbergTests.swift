import UITestsFoundation
import XCTest

class EditorGutenbergTests: XCTestCase {
    override func setUpWithError() throws {
        setUpTestSuite()

        try LoginFlow.login(
            siteUrl: WPUITestCredentials.testWPcomSiteAddress,
            email: WPUITestCredentials.testWPcomUserEmail,
            password: WPUITestCredentials.testWPcomPassword
        )
        try EditorFlow
            .goToMySiteScreen()
            .tabBar.gotoBlockEditorScreen()
            .dismissNotificationAlertIfNeeded(.accept)
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
    }

    let title = "Rich post title"
    let content = "Some text, and more text"

    func testTextPostPublish() throws {

        try BlockEditorScreen()
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
        try BlockEditorScreen()
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

        try BlockEditorScreen()
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
        try BlockEditorScreen()
            .enterTextInTitle(text: title)
            .addParagraphBlock(withText: content)
            .addImageGallery()
            .verifyContentStructure(blocks: 2, words: content.components(separatedBy: " ").count, characters: content.count)
    }
}

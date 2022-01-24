import UITestsFoundation
import XCTest

class EditorAztecTests: XCTestCase {
    private var editorScreen: AztecEditorScreen!

    override func setUpWithError() throws {
        setUpTestSuite()

        _ = try LoginFlow.loginIfNeeded(siteUrl: WPUITestCredentials.testWPcomSiteAddress, email: WPUITestCredentials.testWPcomUserEmail, password: WPUITestCredentials.testWPcomPassword)
        editorScreen = try EditorFlow
            .toggleBlockEditor(to: .off)
            .goBackToMySite()
            .tabBar.goToAztecEditorScreen()
            .dismissNotificationAlertIfNeeded(.accept)
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
        if editorScreen != nil && !TabNavComponent.isVisible() {
            EditorFlow.returnToMainEditorScreen()
            editorScreen.closeEditor()
        }
        try LoginFlow.logoutIfNeeded()
        try super.tearDownWithError()
    }

    // TODO: Re-enable Aztec tests but for editing an existing Aztec post.
    // For more information, see Issue: https://github.com/wordpress-mobile/WordPress-iOS/issues/16218
//    func testTextPostPublish() {
//        let title = getRandomPhrase()
//        let content = getRandomContent()
//        editorScreen
//            .enterTextInTitle(text: title)
//            .enterText(text: content)
//            .publish()
//            .viewPublishedPost(withTitle: title)
//            .verifyEpilogueDisplays(postTitle: title, siteAddress: WPUITestCredentials.testWPcomSitePrimaryAddress)
//            .done()
//    }
//
//    func testBasicPostPublish() {
//        let title = getRandomPhrase()
//        let content = getRandomContent()
//        let category = getCategory()
//        let tag = getTag()
//        editorScreen
//            .enterTextInTitle(text: title)
//            .enterText(text: content)
//            .addImageByOrder(id: 0)
//            .openPostSettings()
//            .selectCategory(name: category)
//            .addTag(name: tag)
//            .setFeaturedImage()
//            .verifyPostSettings(withCategory: category, withTag: tag, hasImage: true)
//            .removeFeatureImage()
//            .verifyPostSettings(withCategory: category, withTag: tag, hasImage: false)
//            .setFeaturedImage()
//            .verifyPostSettings(withCategory: category, withTag: tag, hasImage: true)
//            .closePostSettings()
//        AztecEditorScreen(mode: .rich).publish()
//            .viewPublishedPost(withTitle: title)
//            .verifyEpilogueDisplays(postTitle: title, siteAddress: WPUITestCredentials.testWPcomSitePrimaryAddress)
//            .done()
//    }
//
//    // Github issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/385
//    func testLongTitle() {
//        let longTitle = "long title in a galaxy not so far away"
//        // Title heigh contains of actual textfield height + bottom line.
//        // 16.5px - is the height of that bottom line. Its not changing with different font sizes
//        let titleTextView = editorScreen.titleView
//        let titleLineHeight = titleTextView.frame.height - 16.5
//        let oneLineTitleHeight = titleTextView.frame.height
//
//        let repeatTimes = isIPhone ? 6 : 20
//        _ = editorScreen.enterTextInTitle(text: String(repeating: "very ", count: repeatTimes) + longTitle)
//
//        let twoLineTitleHeight = titleTextView.frame.height
//
//        XCTAssert(twoLineTitleHeight - oneLineTitleHeight >= titleLineHeight )
//    }
}

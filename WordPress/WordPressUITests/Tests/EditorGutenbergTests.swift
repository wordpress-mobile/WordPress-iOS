import XCTest

class EditorGutenbergTests: XCTestCase {
    private var editorScreen: BlockEditorScreen!

    override func setUp() {
        setUpTestSuite()

        _ = LoginFlow.loginIfNeeded(siteUrl: WPUITestCredentials.testWPcomSiteAddress, email: WPUITestCredentials.testWPcomUserEmail, password: WPUITestCredentials.testWPcomPassword)
        editorScreen = EditorFlow
            .gotoMySiteScreen()
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

    func testTextPostPublish() throws {
        try skipTillBloggingRemindersAreHandled()

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

    func testBasicPostPublish() throws {
        try skipTillBloggingRemindersAreHandled()

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

    func testNewBlogPostWithFeaturedImage() {
        let title = getRandomPhrase()
        let content = getRandomContent()
        editorScreen
            .dismissNotificationAlertIfNeeded(.accept)
            .enterTextInTitle(text: title)
            .addParagraphBlock(withText: content)
            .openPostSettings()
            .setFeaturedImage()
            .verifyPostSettings(hasImage: true)
            .closePostSettings()
        BlockEditorScreen().publish()
            .viewPublishedPost(withTitle: title)
            .verifyEpilogueDisplays(postTitle: title, siteAddress: WPUITestCredentials.testWPcomSitePrimaryAddress)
            .done()

    }

    func testNewBlogPostWithDifferentMediaTypes() {
        let title = getRandomPhrase()
        editorScreen
            .dismissNotificationAlertIfNeeded(.accept)
            .enterTextInTitle(text: title)
            .openBlockPicker()
            .addImage()
            .openBlockPicker()
            .addVideo()
            .publish()
            .viewPublishedPost(withTitle: title)
//            .verifyEpilogueDisplays(postTitle: title, siteAddress: WPUITestCredentials.testWPcomSitePrimaryAddress)
            .done()
    }

    func testNewBlogPostSchedulled() {
        let title = getRandomPhrase()
        editorScreen
            .dismissNotificationAlertIfNeeded(.accept)
            .enterTextInTitle(text: title)
            .openPostSettings()
            .setSchedulledPost()
            .closePostSettings()
        BlockEditorScreen().schedule()
            .viewPublishedPost(withTitle: title)
    }

    func testCreateNewPageFromMultiuserAndChangeTheAuthor() {
        editorScreen
            .dismissNotificationAlertIfNeeded(.accept)
    }

    func skipTillBloggingRemindersAreHandled(file: StaticString = #file, line: UInt = #line) throws {
        try XCTSkipIf(true, "Skipping test because we haven't added support for Blogging Reminders. See https://github.com/wordpress-mobile/WordPress-iOS/issues/16797.", file: file, line: line)
    }
}

import XCTest

class SitePageTests: XCTestCase {
    private var sitePageEditorScreen: SitePageScreen!
    override func setUp() {
        setUpTestSuite()
        _ = LoginFlow.loginIfNeeded (siteUrl: WPUITestCredentials.testWPcomSiteAddress, email: WPUITestCredentials.testWPcomUserEmail, password: WPUITestCredentials.testWPcomPassword)
        sitePageEditorScreen = EditorFlow.gotoMySiteScreen()
            .tabBar.gotoSitePageEditorScreen()
    }

    func testCreateNewPageFromLayout() {
        let title = getRandomPhrase()
        sitePageEditorScreen
            .dismissNotificationAlertIfNeeded(.accept)
            .selectALayout()
            .enterTextInTitle(text: title)
            .publish()
            .viewPublishedPost(withTitle: title)
            .verifyEpilogueDisplays(postTitle: title, siteAddress: WPUITestCredentials.testWPcomSitePrimaryAddress)
            .done()
    }

    func testCreateNewBlankPage() {
        let title = getRandomPhrase()
        sitePageEditorScreen
            .dismissNotificationAlertIfNeeded(.accept)
            .tapOnCreateBlankPageButton()
            .enterTextInTitle(text: title)
            .publish()
            .viewPublishedPost(withTitle: title)
            .verifyEpilogueDisplays(postTitle: title, siteAddress: WPUITestCredentials.testWPcomSitePrimaryAddress)
            .done()
    }

    func testCreateNewPageWithFeaturedImage() {
        let title = getRandomPhrase()
        sitePageEditorScreen
            .dismissNotificationAlertIfNeeded(.accept)
            .tapOnCreateBlankPageButton()
            .enterTextInTitle(text: title)
            .openPageSettings()
            .setFeaturedImage()
            .verifyPostSettings(hasImage: true)
            .closePostSettings()
        BlockEditorScreen().publish()
            .viewPublishedPost(withTitle: title)
            .verifyEpilogueDisplays(postTitle: title, siteAddress: WPUITestCredentials.testWPcomSitePrimaryAddress)
            .done()
    }
}

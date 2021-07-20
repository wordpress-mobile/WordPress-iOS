import XCTest

class StoryPageTests: XCTestCase {
    private var storyPostEditorScreen: StoryPageScreen!
    override func setUp() {
        setUpTestSuite()
        _ = LoginFlow.loginIfNeeded(siteUrl: WPUITestCredentials.testWPcomSiteAddress, email: WPUITestCredentials.testWPcomUserEmail, password: WPUITestCredentials.testWPcomPassword)
        storyPostEditorScreen = EditorFlow.gotoMySiteScreen()
            .tabBar.gotoStoryPostEditorScreen()
    }

    func testCreateAStoryUsingPhotos() {
        storyPostEditorScreen
            .pickAnImageFromMedia()
    }
}

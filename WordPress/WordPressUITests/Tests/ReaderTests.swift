import UITestsFoundation
import XCTest

class ReaderTests: XCTestCase {
    private var readerScreen: ReaderScreen!

    override func setUpWithError() throws {
        setUpTestSuite()

        _ = try LoginFlow.loginIfNeeded(siteUrl: WPUITestCredentials.testWPcomSiteAddress, email: WPUITestCredentials.testWPcomUserEmail, password: WPUITestCredentials.testWPcomPassword)
        readerScreen = try EditorFlow
            .goToMySiteScreen()
            .tabBar.goToReaderScreen()
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
        if readerScreen != nil && !TabNavComponent.isVisible() {
            readerScreen.dismissPost()
        }
        try LoginFlow.logoutIfNeeded()
        try super.tearDownWithError()
    }

    let expectedPostContent = "Aenean vehicula nunc in sapien rutrum, nec vehicula enim iaculis. Aenean vehicula nunc in sapien rutrum, nec vehicula enim iaculis. Proin dictum non ligula aliquam varius. Nam ornare accumsan ante, sollicitudin bibendum erat bibendum nec. Aenean vehicula nunc in sapien rutrum, nec vehicula enim iaculis."

    func testViewPostInApp() {
        readerScreen.openTheLastPostInApp()
        XCTAssert(readerScreen.postContentEquals(expected: expectedPostContent))
    }

    func testViewPostInSafari() {
        readerScreen.openTheLastPostInSafari()
        XCTAssert(readerScreen.postContentEquals(expected: expectedPostContent))
    }
}

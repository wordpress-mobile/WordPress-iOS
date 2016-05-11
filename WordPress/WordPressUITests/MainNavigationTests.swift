import XCTest

class MainNavigationTests: XCTestCase {

    override func setUp() {
        super.setUp()

        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        // Logout first if needed
        logoutIfNeeded()
        login()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        logoutIfNeeded()
        super.tearDown()
    }

    func testTabBarNavigation() {
        let app = XCUIApplication()

        let mainNavigationTabBar = app.tabBars["Main Navigation"]

        mainNavigationTabBar.buttons["My Sites"].tap()
        mainNavigationTabBar.buttons["My Sites"].tap()
        self.waitForElementToAppear(app.tables["Blogs"])

        mainNavigationTabBar.buttons["Reader"].tap()
        self.waitForElementToAppear(app.tables["Reader"])

        mainNavigationTabBar.buttons["Me"].tap()
        self.waitForElementToAppear(app.staticTexts["Me"])

        mainNavigationTabBar.buttons["Notifications"].tap()
        self.waitForElementToAppear(app.staticTexts["Notifications"])

        mainNavigationTabBar.buttons["New Post"].tap()
        app.navigationBars["WPPostView"].buttons["Cancel"].tap()
    }

}

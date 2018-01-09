import XCTest

class MainNavigationTests: XCTestCase {

    override func setUp() {
        super.setUp()

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
        BaseScreen.testCase = self

        // Logout first if needed
        logoutIfNeeded()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        logoutIfNeeded()
        super.tearDown()
    }

    func testTabBarNavigation() {
        let app = XCUIApplication()
        let mainNavigationTabBar = app.tabBars["Main Navigation"]
        _ = WelcomeScreen.init().login()
            .proceedWith(email: WPUITestCredentials.testUserEmail)
            .proceedWithPassword()
            .proceedWith(password: WPUITestCredentials.testUserPassword)
            .continueWithSelectedSite()

        self.waitForElementToAppear(element: mainNavigationTabBar)

        mainNavigationTabBar.buttons["My Sites"].tap()
        mainNavigationTabBar.buttons["My Sites"].tap()
        self.waitForElementToAppear(element: app.tables["Blogs"])

        mainNavigationTabBar.buttons["Reader"].tap()
        self.waitForElementToAppear(element: app.tables["Reader"])

        mainNavigationTabBar.buttons["Me"].tap()
        self.waitForElementToAppear(element: app.navigationBars["Me"].otherElements["Me"])

        mainNavigationTabBar.buttons["Notifications"].tap()
        self.waitForElementToAppear(element: app.navigationBars["Notifications"])

        mainNavigationTabBar.buttons["Write"].tap()
        app.buttons["Close"].tap()
    }

}

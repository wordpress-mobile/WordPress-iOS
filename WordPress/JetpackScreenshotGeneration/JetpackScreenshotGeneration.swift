import ScreenObject
import UIKit
import UITestsFoundation
import XCTest

@MainActor
class JetpackScreenshotGeneration: XCTestCase {
    let scanWaitTime: UInt32 = 5

    override func setUp() async throws {
        try await super.setUp()

        let app = XCUIApplication.jetpack

        let arguments = [
            "-ff-override-New Stats", "true",
            "-ui-test-use-mock-data",
            "-ui-test-screenshot-generation"
        ]

        // This does the shared setup including injecting mocks and launching the app
        setUpTestSuite(
            for: app,
            arguments: arguments,
            selectWPComSite: WPUITestCredentials.testWPcomPaidSite
        )

        // The app is already launched so we can set it up for screenshots here
        setupSnapshot(app)

        if XCTestCase.isPad {
            XCUIDevice.shared.orientation = UIDeviceOrientation.landscapeLeft
        } else {
            XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        }
    }

    func testGenerateScreenshots() throws {
        let app = XCUIApplication()

        // 2. Editor
        try MySiteScreen()
            .goToCreateSheet()
            .openMockPost()
            .thenTakeScreenshot(2, named: "Gutenberg")
            .closeEditor()

        if XCTestCase.isPad {
            // 4. Notifications
            app.buttons["bar-button-item-notifications"].firstMatch.tap()
            try NotificationsScreen()
                .thenTakeScreenshot(4, named: "Notifications")
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                .tap()
        }

        // 1. Stats
        try MySiteScreen()
            .goToMoreMenu()
            .goToStatsScreen()
            .waitUntilDataLoaded()
            .thenTakeScreenshot(1, named: "Stats")

        if XCTestCase.isPhone {
            // 4. Notifications
            app.navigationBars.buttons.element(boundBy: 0).tap() // go back

            try makeMainNavigationComponent()
                .goToNotificationsScreen()
                .thenTakeScreenshot(4, named: "Notifications")
        }

        // 3. Reader
        try makeMainNavigationComponent()
            .openReaderMenu()
            .selectSubscription(named: "WordPress.com News")
            .openFirstPost()
            .thenTakeScreenshot(3, named: "Reader")
        app.navigationBars.buttons.element(boundBy: 0).tap() // go back
    }
}

extension ScreenObject {

    @MainActor @discardableResult
    func thenTakeScreenshot(_ index: Int, named title: String) -> Self {
        let mode = XCUIDevice.inDarkMode ? "dark" : "light"
        let filename = "\(index)-\(mode)-\(title)"

        snapshot(filename)

        return self
    }
}

private extension MainNavigationComponent {
    func openReaderMenu() throws -> ReaderMenuScreen {
        try goToReaderScreen()
        return try ReaderMenuScreen()
    }
}

extension XCUIApplication {

    static let jetpack = XCUIApplication(bundleIdentifier: "com.automattic.jetpack")
}

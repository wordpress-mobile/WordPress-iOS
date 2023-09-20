import ScreenObject
import XCTest

public class MySiteMoreMenuScreen: ScreenObject {

    private let activityLogButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["Activity Log Row"]
    }

    private let blogDetailsTableGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["Blog Details Table"]
    }

    private let postsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["Blog Post Row"]
    }

    private let mediaButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["Media Row"]
    }

    private let mySiteNavigationBarGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars["my-site-navigation-bar"]
    }

    private let statsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["Stats Row"]
    }

    private let domainsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["Domains Row"]
    }

    private let jetpackScanButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["Scan Row"]
    }

    private let jetpackBackupButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["Backup Row"]
    }

    private let settingsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["Settings Row"]
    }

    private let peopleButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["People Row"]
    }

    var activityLogButton: XCUIElement { activityLogButtonGetter(app) }
    var blogDetailsTable: XCUIElement { blogDetailsTableGetter(app) }
    var domainsButton: XCUIElement { domainsButtonGetter(app) }
    var jetpackBackupButton: XCUIElement { jetpackBackupButtonGetter(app) }
    var jetpackScanButton: XCUIElement { jetpackScanButtonGetter(app) }
    var mediaButton: XCUIElement { mediaButtonGetter(app) }
    var mySiteNavigationBar: XCUIElement { mySiteNavigationBarGetter(app) }
    var peopleButton: XCUIElement { peopleButtonGetter(app) }
    var postsButton: XCUIElement { postsButtonGetter(app) }
    var settingsButton: XCUIElement { settingsButtonGetter(app) }
    var statsButton: XCUIElement { statsButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                blogDetailsTableGetter,
                activityLogButtonGetter,
                mySiteNavigationBarGetter
            ],
            app: app
        )
    }

    public func goToPostsScreen() throws -> PostsScreen {
        postsButton.tap()
        return try PostsScreen()
    }

    public func goToActivityLog() throws -> ActivityLogScreen {
        activityLogButton.tap()
        return try ActivityLogScreen()
    }

    public func goToJetpackScan() throws -> JetpackScanScreen {
        jetpackScanButton.tap()
        return try JetpackScanScreen()
    }

    public func goToJetpackBackup() throws -> JetpackBackupScreen {
        jetpackBackupButton.tap()
        return try JetpackBackupScreen()
    }

    public func goToMediaScreen() throws -> MediaScreen {
        mediaButton.tap()
        return try MediaScreen()
    }

    public func goToStatsScreen() throws -> StatsScreen {
        statsButton.tap()
        return try StatsScreen()
    }

    @discardableResult
    public func goToSettingsScreen() throws -> SiteSettingsScreen {
        settingsButton.tap()
        return try SiteSettingsScreen()
    }

    public func goToDomainsScreen() throws -> DomainsScreen {
        domainsButton.tap()
        return try DomainsScreen()
    }

    @discardableResult
    public func goToPeople() throws -> PeopleScreen {
        peopleButton.tap()
        return try PeopleScreen()
    }

    public static func isLoaded() -> Bool {
        (try? MySiteMoreMenuScreen().isLoaded) ?? false
    }
}

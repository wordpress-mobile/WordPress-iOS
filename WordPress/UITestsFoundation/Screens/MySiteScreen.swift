import XCTest

private struct ElementStringIDs {
    static let navBarTitle = "my-site-navigation-bar"
    static let blogTable = "Blog Details Table"
    static let removeSiteButton = "BlogDetailsRemoveSiteCell"
    static let activityLogButton = "Activity Log Row"
    static let jetpackScanButton = "Scan Row"
    static let jetpackBackupButton = "Backup Row"
    static let postsButton = "Blog Post Row"
    static let mediaButton = "Media Row"
    static let statsButton = "Stats Row"
    static let settingsButton = "Settings Row"
    static let createButton = "floatingCreateButton"
    static let ReaderButton = "Reader"
    static let switchSiteButton = "SwitchSiteButton"
}

/// The home-base screen for an individual site. Used in many of our UI tests.
public class MySiteScreen: BaseScreen {
    public let tabBar: TabNavComponent
    let navBar: XCUIElement
    let removeSiteButton: XCUIElement
    let removeSiteSheet: XCUIElement
    let removeSiteAlert: XCUIElement
    let activityLogButton: XCUIElement
    let jetpackScanButton: XCUIElement
    let jetpackBackupButton: XCUIElement
    let postsButton: XCUIElement
    let mediaButton: XCUIElement
    let statsButton: XCUIElement
    let siteSettingsButton: XCUIElement
    let createButton: XCUIElement
    let readerButton: XCUIElement
    let switchSiteButton: XCUIElement

    static var isVisible: Bool {
        let app = XCUIApplication()
        let blogTable = app.tables[ElementStringIDs.blogTable]
        return blogTable.exists && blogTable.isHittable
    }

    public init() throws {
        let app = XCUIApplication()
        tabBar = try TabNavComponent()
        removeSiteButton = app.cells[ElementStringIDs.removeSiteButton]
        removeSiteSheet = app.sheets.buttons.element(boundBy: 0)
        removeSiteAlert = app.alerts.buttons.element(boundBy: 1)
        activityLogButton = app.cells[ElementStringIDs.activityLogButton]
        jetpackScanButton = app.cells[ElementStringIDs.jetpackScanButton]
        jetpackBackupButton = app.cells[ElementStringIDs.jetpackBackupButton]
        postsButton = app.cells[ElementStringIDs.postsButton]
        mediaButton = app.cells[ElementStringIDs.mediaButton]
        statsButton = app.cells[ElementStringIDs.statsButton]
        siteSettingsButton = app.cells[ElementStringIDs.settingsButton]
        createButton = app.buttons[ElementStringIDs.createButton]
        readerButton = app.buttons[ElementStringIDs.ReaderButton]
        switchSiteButton = app.buttons[ElementStringIDs.switchSiteButton]
        navBar = app.navigationBars[ElementStringIDs.navBarTitle]

        super.init(element: navBar)
    }

    public func showSiteSwitcher() -> MySitesScreen {
        switchSiteButton.tap()
        return MySitesScreen()
    }

    public func removeSelfHostedSite() {
        removeSiteButton.tap()
        if XCUIDevice.isPad {
            removeSiteAlert.tap()
        } else {
            removeSiteSheet.tap()
        }
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

    public func gotoPostsScreen() -> PostsScreen {
        // A hack for iPad, because sometimes tapping "posts" doesn't load it the first time
        if XCUIDevice.isPad {
            mediaButton.tap()
        }

        postsButton.tap()
        return PostsScreen()
    }

    public func gotoMediaScreen() -> MediaScreen {
        mediaButton.tap()
        return MediaScreen()
    }

    public func goToStatsScreen() throws -> StatsScreen {
        statsButton.tap()
        return try StatsScreen()
    }

    public func goToSettingsScreen() throws -> SiteSettingsScreen {
        siteSettingsButton.tap()
        return try SiteSettingsScreen()
    }

    func gotoCreateSheet() throws -> ActionSheetComponent {
        createButton.tap()
        return try ActionSheetComponent()
    }

    public static func isLoaded() -> Bool {
        return XCUIApplication().navigationBars[ElementStringIDs.navBarTitle].exists
    }
}

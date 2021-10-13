import ScreenObject
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
public class MySiteScreen: ScreenObject {
    public let tabBar: TabNavComponent

    let activityLogButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells[ElementStringIDs.activityLogButton]
    }

    let postsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells[ElementStringIDs.postsButton]
    }

    let mediaButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells[ElementStringIDs.mediaButton]
    }

    var mediaButton: XCUIElement { mediaButtonGetter(app) }

    let statsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells[ElementStringIDs.statsButton]
    }

    let createButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons[ElementStringIDs.createButton]
    }
    let readerButton: XCUIElement

    let switchSiteButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons[ElementStringIDs.switchSiteButton]
    }

    static var isVisible: Bool {
        let app = XCUIApplication()
        let blogTable = app.tables[ElementStringIDs.blogTable]
        return blogTable.exists && blogTable.isHittable
    }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        tabBar = try TabNavComponent()
        readerButton = app.buttons[ElementStringIDs.ReaderButton]

        try super.init(
            expectedElementGetters: [
                switchSiteButtonGetter,
                statsButtonGetter,
                postsButtonGetter,
                mediaButtonGetter,
                createButtonGetter
            ],
            app: app
        )
    }

    public func showSiteSwitcher() throws -> MySitesScreen {
        switchSiteButtonGetter(app).tap()
        return try MySitesScreen()
    }

    public func removeSelfHostedSite() {
        app.cells[ElementStringIDs.removeSiteButton].tap()
        // TODO: Wouldn't it be better to do this with an accessibility label?
        let index = XCUIDevice.isPad ? 1 : 0
        app.sheets.buttons.element(boundBy: index).tap()
    }

    public func goToActivityLog() throws -> ActivityLogScreen {
        app.cells[ElementStringIDs.activityLogButton].tap()
        return try ActivityLogScreen()
    }

    public func goToJetpackScan() throws -> JetpackScanScreen {
        app.cells[ElementStringIDs.jetpackScanButton].tap()
        return try JetpackScanScreen()
    }

    public func goToJetpackBackup() throws -> JetpackBackupScreen {
        app.cells[ElementStringIDs.jetpackBackupButton].tap()
        return try JetpackBackupScreen()
    }

    public func gotoPostsScreen() throws -> PostsScreen {
        // A hack for iPad, because sometimes tapping "posts" doesn't load it the first time
        if XCUIDevice.isPad {
            mediaButton.tap()
        }

        postsButtonGetter(app).tap()
        return try PostsScreen()
    }

    public func gotoMediaScreen() -> MediaScreen {
        mediaButton.tap()
        return MediaScreen()
    }

    public func goToStatsScreen() throws -> StatsScreen {
        statsButtonGetter(app).tap()
        return try StatsScreen()
    }

    public func goToSettingsScreen() throws -> SiteSettingsScreen {
        app.cells[ElementStringIDs.settingsButton].tap()
        return try SiteSettingsScreen()
    }

    func gotoCreateSheet() throws -> ActionSheetComponent {
        createButtonGetter(app).tap()
        return try ActionSheetComponent()
    }

    public static func isLoaded() -> Bool {
        (try? MySiteScreen().isLoaded) ?? false
    }
}

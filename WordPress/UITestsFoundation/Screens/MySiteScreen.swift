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
    static let peopleButton = "People Row"
    static let settingsButton = "Settings Row"
    static let domainsButton = "Domains Row"
    static let createButton = "floatingCreateButton"
    static let ReaderButton = "Reader"
    static let switchSiteButton = "SwitchSiteButton"
    static let dashboardButton = "Home"
    static let segmentedControlMenuButton = "Menu"
    static let domainsCardHeaderButton = "Find a custom domain"
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

    let homeButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons[ElementStringIDs.dashboardButton]
    }

    let segmentedControlMenuButton: (XCUIApplication) -> XCUIElement = {
        $0.buttons[ElementStringIDs.segmentedControlMenuButton]
    }

    let domainsCardButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons[ElementStringIDs.domainsCardHeaderButton]
    }

    let domainsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells[ElementStringIDs.domainsButton]
    }

    var domainsCardButton: XCUIElement { domainsCardButtonGetter(app) }

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
            app: app,
            waitTimeout: 7
        )
    }

    public func showSiteSwitcher() throws -> MySitesScreen {
        switchSiteButtonGetter(app).tap()
        return try MySitesScreen()
    }

    public func removeSelfHostedSite() {
        app.tables[ElementStringIDs.blogTable].swipeUp(velocity: .fast)
        app.cells[ElementStringIDs.removeSiteButton].doubleTap()

        let removeButton: XCUIElement
        if XCUIDevice.isPad {
            removeButton = app.alerts.buttons.element(boundBy: 1)
        } else {
            removeButton = app.buttons["Remove Site"]
        }

        removeButton.tap()
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

    public func goToMediaScreen() throws -> MediaScreen {
        mediaButton.tap()
        return try MediaScreen()
    }

    public func goToStatsScreen() throws -> StatsScreen {
        statsButtonGetter(app).tap()
        return try StatsScreen()
    }

    public func goToSettingsScreen() throws -> SiteSettingsScreen {
        app.cells[ElementStringIDs.settingsButton].tap()
        return try SiteSettingsScreen()
    }

    public func goToCreateSheet() throws -> ActionSheetComponent {
        createButtonGetter(app).tap()
        return try ActionSheetComponent()
    }

    public func goToHomeScreen() -> Self {
        homeButtonGetter(app).tap()
        return self
    }

    public func goToDomainsScreen() throws -> DomainsScreen {
        app.cells[ElementStringIDs.domainsButton].tap()
        return try DomainsScreen()
    }

    @discardableResult
    public func goToMenu() -> Self {
        // On iPad, the menu items are already listed on screen, so we don't need to tap the menu button
        guard XCUIDevice.isPhone else {
            return self
        }

        segmentedControlMenuButton(app).tap()
        return self
    }

    @discardableResult
    public func goToPeople() throws -> PeopleScreen {
        app.cells[ElementStringIDs.peopleButton].tap()
        return try PeopleScreen()
    }

    public static func isLoaded() -> Bool {
        (try? MySiteScreen().isLoaded) ?? false
    }

    @discardableResult
    public func verifyDomainsCard() -> Self {
        let cardText = app.staticTexts["Stake your claim on your corner of the web with a site address that’s easy to find, share and follow."]
        XCTAssertTrue(domainsCardButton.waitForIsHittable(), "Domains card header was not displayed.")
        XCTAssertTrue(cardText.waitForIsHittable(), "Domains card text was not displayed.")
        return self
    }

    @discardableResult
    public func tapDomainsCard() throws -> DomainsSuggestionsScreen {
        domainsCardButton.tap()
        return try DomainsSuggestionsScreen()
    }

    @discardableResult
    public func scrollToDomainsCard() throws -> Self {
        let collectionView = app.collectionViews.firstMatch
        let cardCell = collectionView.cells.containing(.other, identifier: "dashboard-domains-card-contentview").firstMatch
        cardCell.scrollIntoView(within: collectionView)
        return self
    }
}

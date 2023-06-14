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
    // "Free To Paid Plans" Card
    static let freeToPaidPlansCardId = "dashboard-free-to-paid-plans-card-contentview"
    static let freeToPaidPlansCardHeaderButton = "Free domain with an annual plan"
    // "Pages" Card
    static let pagesCardId = "dashboard-pages-card-frameview"
    static let pagesCardHeaderButton = "Pages"
    static let pagesCardMoreButton = "More"
    static let pagesCardCreatePageButton = "Create another page"
    // "Activity Log" Card
    static let activityLogCardId = "dashboard-activity-log-card-frameview"
    static let activityLogCardHeaderButton = "Recent activity"
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

    let freeToPaidPlansCardButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons[ElementStringIDs.freeToPaidPlansCardHeaderButton]
    }

    let pagesCardGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements[ElementStringIDs.pagesCardId]
    }

    let pagesCardHeaderButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements[ElementStringIDs.pagesCardId].buttons[ElementStringIDs.pagesCardHeaderButton]
    }

    let pagesCardMoreButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements[ElementStringIDs.pagesCardId].buttons[ElementStringIDs.pagesCardHeaderButton]
    }

    let pagesCardCreatePageButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements[ElementStringIDs.pagesCardId].buttons[ElementStringIDs.pagesCardMoreButton]
    }

    let domainsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells[ElementStringIDs.domainsButton]
    }

    let activityLogCardGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements[ElementStringIDs.activityLogCardId]
    }

    let activityLogCardHeaderButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements[ElementStringIDs.activityLogCardId].buttons[ElementStringIDs.activityLogCardHeaderButton]
    }

    var freeToPaidPlansCardButton: XCUIElement { freeToPaidPlansCardButtonGetter(app) }
    var pagesCard: XCUIElement { pagesCardGetter(app) }
    var pagesCardHeaderButton: XCUIElement { pagesCardHeaderButtonGetter(app) }
    var pagesCardMoreButton: XCUIElement { pagesCardMoreButtonGetter(app) }
    var pagesCardCreatePageButton: XCUIElement { pagesCardCreatePageButtonGetter(app) }
    var activityLogCard: XCUIElement { activityLogCardGetter(app) }
    var activityLogCardHeaderButton: XCUIElement { activityLogCardHeaderButtonGetter(app) }

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
    public func verifyFreeToPaidPlansCard() -> Self {
        let cardText = app.staticTexts["Get a free domain for the first year, remove ads on your site, and increase your storage."]
        XCTAssertTrue(freeToPaidPlansCardButton.waitForIsHittable(), "Free to Paid plans card header was not displayed.")
        XCTAssertTrue(cardText.waitForIsHittable(), "Free to Paid plans card text was not displayed.")
        return self
    }

    @discardableResult
    public func verifyPagesCard() -> Self {
        XCTAssertTrue(pagesCardHeaderButton.waitForIsHittable(), "Pages card: Header not displayed.")
        XCTAssertTrue(pagesCardMoreButton.waitForIsHittable(), "Pages card: Context menu button not displayed.")
        XCTAssertTrue(pagesCardCreatePageButton.waitForIsHittable(), "Pages card: \"Create Page\" button not displayed.")
        return self
    }

    @discardableResult
    public func verifyPagesCard(hasPage pageTitle: String) -> Self {
        XCTAssertTrue(pagesCard.staticTexts[pageTitle].waitForIsHittable(), "Pages card: \"\(pageTitle)\" page not displayed.")
        return self
    }

    @discardableResult
    public func verifyActivityLogCard() -> Self {
        XCTAssertTrue(activityLogCardHeaderButton.waitForIsHittable(), "Activity Log card: header not displayed.")
        XCTAssertTrue(activityLogCard.buttons["More"].waitForIsHittable(), "Activity Log card: context menu not displayed.")
        return self
    }

    @discardableResult
    public func verifyActivityLogCard(hasActivityPartial activityTitle: String) -> Self {
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", activityTitle)).firstMatch.waitForIsHittable(),
            "Activity Log card: \"\(activityTitle)\" activity not displayed.")
        return self
    }

    @discardableResult
    public func tapFreeToPaidPlansCard() throws -> DomainsSuggestionsScreen {
        freeToPaidPlansCardButton.tap()
        return try DomainsSuggestionsScreen()
    }

    @discardableResult
    public func scrollToFreeToPaidPlansCard() throws -> Self {
        scrollToCard(withId: ElementStringIDs.freeToPaidPlansCardId)
        return self
    }

    @discardableResult
    public func scrollToPagesCard() throws -> Self {
        scrollToCard(withId: ElementStringIDs.pagesCardId)
        return self
    }

    @discardableResult
    public func tapPagesCardHeader() throws -> PagesScreen {
        pagesCardHeaderButton.tap()
        return try PagesScreen()
    }

    @discardableResult
    public func scrollToActivityLogCard() throws -> Self {
        scrollToCard(withId: ElementStringIDs.activityLogCardId)
        return self
    }

    @discardableResult
    public func tapActivityLogCardHeader() throws -> ActivityLogScreen {
        activityLogCardHeaderButton.tap()
        return try ActivityLogScreen()
    }

    func scrollToCard(withId id: String) {
        let collectionView = app.collectionViews.firstMatch
        let cardCell = collectionView.cells.containing(.any, identifier: id).firstMatch
        app.scrollDownToElement(element: cardCell)
    }
}

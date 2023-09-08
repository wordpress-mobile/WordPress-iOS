import ScreenObject
import XCTest

/// The home-base screen for an individual site. Used in many of our UI tests.
public class MySiteScreen: ScreenObject {

    static let activityLogCardId = "dashboard-activity-log-card-frameview"
    static let freeToPaidPlansCardId = "dashboard-free-to-paid-plans-card-contentview"
    static let pagesCardId = "dashboard-pages-card-frameview"

    private let readerButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Reader"]
    }

    private let createButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["floatingCreateButton"]
    }

    private let switchSiteButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["SwitchSiteButton"]
    }

    private let moreMenuButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables.cells.staticTexts["More"]
    }

    private let freeToPaidPlansCardButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Free domain with an annual plan"]
    }

    private let pagesCardGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements[pagesCardId]
    }

    private let pagesCardHeaderButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements[pagesCardId].buttons["Pages"]
    }

    private let pagesCardMoreButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements[pagesCardId].buttons["More"]
    }

    private let pagesCardCreatePageButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements[pagesCardId].buttons["Create another page"]
    }

    private let domainsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["Domains Row"]
    }

    private let activityLogCardGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements[activityLogCardId]
    }

    private let activityLogCardHeaderButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements[activityLogCardId].buttons["Recent activity"]
    }

    private let blogTableGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["Blog Details Table"]
    }

    private let blogDetailsRemoveSiteButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["BlogDetailsRemoveSiteCell"]
    }

    private let removeSiteButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Remove Site"]
    }

    private let removeSiteAlertGetter: (XCUIApplication) -> XCUIElement = {
        $0.alerts.buttons.element(boundBy: 1)
    }

    private let noticeTitleGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements["notice_title_and_message"]
    }

    var activityLogCard: XCUIElement { activityLogCardGetter(app) }
    var activityLogCardHeaderButton: XCUIElement { activityLogCardHeaderButtonGetter(app) }
    var blogDetailsRemoveSiteButton: XCUIElement { blogDetailsRemoveSiteButtonGetter(app) }
    var blogTable: XCUIElement { blogTableGetter(app) }
    var createButton: XCUIElement { createButtonGetter(app) }
    var domainsButton: XCUIElement { domainsButtonGetter(app) }
    var freeToPaidPlansCardButton: XCUIElement { freeToPaidPlansCardButtonGetter(app) }
    var moreMenuButton: XCUIElement { moreMenuButtonGetter(app) }
    var noticeTitle: XCUIElement { noticeTitleGetter(app) }
    var pagesCard: XCUIElement { pagesCardGetter(app) }
    var pagesCardCreatePageButton: XCUIElement { pagesCardCreatePageButtonGetter(app) }
    var pagesCardHeaderButton: XCUIElement { pagesCardHeaderButtonGetter(app) }
    var pagesCardMoreButton: XCUIElement { pagesCardMoreButtonGetter(app) }
    var readerButton: XCUIElement { readerButtonGetter(app)}
    var removeSiteAlert: XCUIElement { removeSiteAlertGetter(app) }
    var removeSiteButton: XCUIElement { removeSiteButtonGetter(app) }
    var switchSiteButton: XCUIElement { switchSiteButtonGetter(app)}

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                switchSiteButtonGetter,
                createButtonGetter
            ],
            app: app
        )
    }

    public func showSiteSwitcher() throws -> MySitesScreen {
        switchSiteButton.tap()
        return try MySitesScreen()
    }

    public func removeSelfHostedSite() {
        blogTable.swipeUp(velocity: .fast)
        blogDetailsRemoveSiteButton.doubleTap()

        let removeButton = XCUIDevice.isPad ? removeSiteAlert : removeSiteButton
        removeButton.tap()
    }

    public func goToCreateSheet() throws -> ActionSheetComponent {
        createButton.tap()
        return try ActionSheetComponent()
    }

    public func goToDomainsScreen() throws -> DomainsScreen {
        domainsButton.tap()
        return try DomainsScreen()
    }

    @discardableResult
    public func goToMoreMenu() throws -> MySiteMoreMenuScreen {

        // On iPad, the menu items are already listed on screen, so we don't need to tap the menu button
        guard XCUIDevice.isPhone && !moreMenuButton.isSelected else {
            return try MySiteMoreMenuScreen()
        }

        moreMenuButton.tap()
        return try MySiteMoreMenuScreen()
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
        scrollToCard(withId: MySiteScreen.freeToPaidPlansCardId)
        return self
    }

    @discardableResult
    public func scrollToPagesCard() throws -> Self {
        scrollToCard(withId: MySiteScreen.pagesCardId)
        return self
    }

    @discardableResult
    public func tapPagesCardHeader() throws -> PagesScreen {
        pagesCardHeaderButton.tap()
        return try PagesScreen()
    }

    @discardableResult
    public func scrollToActivityLogCard() throws -> Self {
        scrollToCard(withId: MySiteScreen.activityLogCardId)
        return self
    }

    @discardableResult
    public func tapActivityLogCardHeader() throws -> ActivityLogScreen {
        activityLogCardHeaderButton.tap()
        return try ActivityLogScreen()
    }

    @discardableResult
    public func verifyCheckSiteTitleNoticeDisplayed(_ siteTitle: String, file: StaticString = #file, line: UInt = #line) -> Self {
        XCTAssertTrue(noticeTitle.exists, file: file, line: line)
        XCTAssertTrue(noticeTitle.label.contains("Select \(siteTitle) to set a new title"), "Notice does not contain site title!")

        return self
    }

    private func scrollToCard(withId id: String) {
        let collectionView = app.collectionViews.firstMatch
        let cardCell = collectionView.cells.containing(.any, identifier: id).firstMatch
        app.scrollDownToElement(element: cardCell)
    }
}

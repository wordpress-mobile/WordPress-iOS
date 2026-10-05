import XCTest

/// The site's stats.
///
/// The Traffic tab's cards are in `StatsScreen+Traffic.swift`, and the Insights and Subscribers
/// tabs' in `StatsScreen+Insights.swift`.
final class StatsScreen: ScreenObject {
    enum Tab: String, CaseIterable {
        case traffic, insights, subscribers
    }

    private let dashboardGetter: ElementGetter = {
        $0.otherElements["stats-dashboard"]
    }

    private let filterBarGetter: ElementGetter = {
        $0.otherElements["site-stats-dashboard-filter-bar"]
    }

    /// The container of the selected tab's cards.
    var content: XCUIElement { dashboardGetter(app) }
    var filterBar: XCUIElement { filterBarGetter(app) }

    /// The Traffic tab's date controls float over its cards.
    override var bottomOverlays: [XCUIElement] {
        [app.buttons["stats_date_range_button"]] + super.bottomOverlays
    }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [dashboardGetter, filterBarGetter], app: app)
    }

    /// The Locations card's map pans when a swipe starts on it, and it fills the middle of the
    /// screen for part of the way down, so this drags along the margin beside the cards instead.
    override func swipeUp(_ scrollView: XCUIElement) {
        let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.99, dy: 0.7))
        let end = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.99, dy: 0.3))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    @discardableResult
    func select(_ tab: Tab) throws -> Self {
        try select(tab: filterBar.buttons[tab.rawValue])
        return self
    }

    func openNavigationBarMenu() throws -> MenuComponent {
        try tap(app.navigationBars.buttons["More"])
        return try MenuComponent(expecting: "Send Feedback", app: app)
    }

    /// How many swipes it can take to reach the bottom of the Traffic tab. Its length depends on
    /// how much data its cards have to show.
    static let maxSwipes = 24

    /// Scrolls the selected tab to `element` and taps it. The cards are in a lazy stack, so one
    /// that's further down doesn't exist until it's scrolled to.
    func scrollAndTap(_ element: XCUIElement) throws {
        try scroll(to: element, in: content, maxSwipes: Self.maxSwipes, waitsForExistence: false)
        element.tap()
    }
}

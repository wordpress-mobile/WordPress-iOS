import XCTest

/// The Insights and Subscribers tabs. Their cards have no accessibility identifiers, so they're
/// found by their titles.
extension StatsScreen {
    enum Insight: String {
        case totalLikes = "Total Likes"
        case totalComments = "Total Comments"
        case totalSubscribers = "Total Subscribers"
    }

    enum InsightsChart: String, CaseIterable {
        case visitors = "Visitors"
        case views = "Views"
    }

    private func card(titled title: String) -> XCUIElement {
        app.tables.cells.containing(.staticText, identifier: title).firstMatch
    }

    // MARK: - Insights

    func goToViewsAndVisitors() throws -> StatsDetailsScreen {
        try scrollAndTap(app.tables.buttons["Week"])
        return try StatsDetailsScreen(title: "Views & Visitors", app: app)
    }

    /// Switches the Views & Visitors card's chart.
    @discardableResult
    func select(_ chart: InsightsChart) throws -> Self {
        let button = app.segmentedControls.buttons[chart.rawValue]
        try scroll(to: button, in: content, waitsForExistence: false)
        try select(tab: button)
        return self
    }

    func goToDetails(of insight: Insight) throws -> StatsDetailsScreen {
        try scrollAndTap(card(titled: insight.rawValue).buttons["View more"])
        return try StatsDetailsScreen(title: insight.rawValue, app: app)
    }

    func goToLatestPost() throws -> WebPreviewScreen {
        try scrollAndTap(card(titled: "Latest Post Summary"))
        return try WebPreviewScreen(app: app)
    }

    func goToManageStatsCards() throws -> ManageStatsCardsScreen {
        try tap(app.navigationBars.buttons["Gear shape"])
        return try ManageStatsCardsScreen(app: app)
    }

    func goToManageStatsCardsFromAddCard() throws -> ManageStatsCardsScreen {
        try scrollAndTap(app.tables.cells["Add stats card"])
        return try ManageStatsCardsScreen(app: app)
    }

    // MARK: - Subscribers

    func goToAllSubscribers() throws -> SubscribersScreen {
        try scrollAndTap(app.tables.buttons["View more"].firstMatch)
        return try SubscribersScreen(app: app)
    }
}

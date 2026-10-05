import XCTest

/// Navigation from the cards on My Site's dashboard.
extension MySiteScreen {
    enum DashboardCard: String {
        case prompts
        case blaze
        case todaysStats = "todays_stats_new"
        case draftPosts
        case pages
        case activityLog = "activity_log"
        case personalize
    }

    // MARK: - Cards

    func goToStatsFromDashboardCard() throws -> StatsScreen {
        try scrollAndTap(cell(for: .todaysStats))
        return try StatsScreen(app: app)
    }

    func goToBlazeFromDashboardCard() throws -> BlazeOverlayScreen {
        try scrollAndTap(cell(for: .blaze))
        return try BlazeOverlayScreen(app: app)
    }

    func goToPersonalizeHomeScreen() throws -> PersonalizeHomeScreen {
        try scrollAndTap(cell(for: .personalize))
        return try PersonalizeHomeScreen(app: app)
    }

    func goToPromptResponsesFromDashboardCard() throws -> PromptResponsesScreen {
        try scrollAndTap(cell(for: .prompts).buttons["View all responses"])
        return try PromptResponsesScreen(app: app)
    }

    // MARK: - Card Headers

    func goToDraftsFromDashboardCard() throws -> PostsScreen {
        try scrollAndTap(header(of: .draftPosts))
        return try PostsScreen(app: app)
    }

    func goToPagesFromDashboardCard() throws -> PagesScreen {
        try scrollAndTap(header(of: .pages))
        return try PagesScreen(app: app)
    }

    func goToActivityLogFromDashboardCard() throws -> ActivityLogScreen {
        try scrollAndTap(header(of: .activityLog))
        return try ActivityLogScreen(app: app)
    }

    // MARK: - Card Rows

    func goToFirstDraftFromDashboardCard() throws -> EditorScreen {
        try scrollAndTap(cell(for: .draftPosts).tables.cells.firstMatch)
        return try EditorScreen(app: app)
    }

    func goToFirstPageFromDashboardCard() throws -> EditorScreen {
        try scrollAndTap(cell(for: .pages).tables.cells.firstMatch)
        return try EditorScreen(app: app)
    }

    func goToFirstActivityFromDashboardCard() throws -> ActivityDetailsScreen {
        // The header and the menu button are the card's only buttons with an identifier.
        let rows = try cell(for: .activityLog).buttons.matching(NSPredicate(format: "identifier == ''"))
        try scrollAndTap(rows.firstMatch)
        return try ActivityDetailsScreen(app: app)
    }

    // MARK: - Card Menus

    func goToDraftsFromDashboardCardMenu() throws -> PostsScreen {
        try tapMenuItem("View all drafts", of: .draftPosts)
        return try PostsScreen(app: app)
    }

    func goToPagesFromDashboardCardMenu() throws -> PagesScreen {
        try tapMenuItem("All pages", of: .pages)
        return try PagesScreen(app: app)
    }

    func goToActivityLogFromDashboardCardMenu() throws -> ActivityLogScreen {
        try tapMenuItem("All activity", of: .activityLog)
        return try ActivityLogScreen(app: app)
    }

    func goToPromptsListFromDashboardCardMenu() throws -> PromptsListScreen {
        try tapMenuItem("View more prompts", of: .prompts)
        return try PromptsListScreen(app: app)
    }

    func goToPromptsIntroductionFromDashboardCardMenu() throws -> PromptsIntroductionScreen {
        try tapMenuItem("Learn more", of: .prompts)
        return try PromptsIntroductionScreen(app: app)
    }

    func goToBlazeFromDashboardCardMenu() throws -> BlazeOverlayScreen {
        try tapMenuItem("Learn more", of: .blaze)
        return try BlazeOverlayScreen(app: app)
    }

    // MARK: - Helpers

    /// The cell for a card, once the dashboard has loaded.
    ///
    /// The dashboard only shows a card when the site has something to put in it: the Activity Log
    /// card needs recent activity, the Draft Posts card needs a draft. Not having that isn't a
    /// failure of the app, so this skips the test instead.
    private func cell(for card: DashboardCard) throws -> XCUIElement {
        let cards = app.collectionViews.cells
        try wait(until: "the dashboard's cards") {
            // The Personalize card is always last, and placeholders stand in for the rest while
            // they load.
            cards["dashboard-card-personalize"].exists && !cards["dashboard-card-ghost"].firstMatch.exists
        }

        let cell = cards["dashboard-card-\(card.rawValue)"]
        guard cell.exists else {
            throw XCTSkip("The dashboard isn't showing the \(card) card for this site")
        }
        return cell
    }

    private func header(of card: DashboardCard) throws -> XCUIElement {
        try cell(for: card).buttons["dashboard-card-header"]
    }

    private func scrollAndTap(_ element: XCUIElement) throws {
        try scroll(to: element, in: content)
        element.tap()
    }

    private func tapMenuItem(_ title: String, of card: DashboardCard) throws {
        try scrollAndTap(cell(for: card).buttons["dashboard-card-more-button"])
        try waitFor(app.buttons[title])
        app.buttons[title].tap()
    }
}

import XCTest

/// The full site menu, opened from My Site's "More" row.
final class SiteMenuScreen: ScreenObject {
    private let listGetter: ElementGetter = {
        $0.collectionViews["Blog Details Table"]
    }

    /// On an iPad the list isn't hittable itself, though its rows are, so the screen waits for one.
    private let firstRowGetter: ElementGetter = {
        $0.collectionViews["Blog Details Table"].buttons.firstMatch
    }

    var list: XCUIElement { listGetter(app) }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [firstRowGetter], app: app)
    }

    func goToPosts() throws -> PostsScreen {
        try open(row: "Blog Post Row")
        return try PostsScreen(app: app)
    }

    func goToPages() throws -> PagesScreen {
        try open(row: "Site Pages Row")
        return try PagesScreen(app: app)
    }

    func goToMedia() throws -> MediaScreen {
        try open(row: "Media Row")
        return try MediaScreen(app: app)
    }

    func goToComments() throws -> CommentsScreen {
        try open(row: "Comments Row")
        return try CommentsScreen(app: app)
    }

    func goToStats() throws -> StatsScreen {
        try open(row: "Stats Row")
        return try StatsScreen(app: app)
    }

    func goToSubscribers() throws -> SubscribersScreen {
        try open(row: "Subscribers Row")
        return try SubscribersScreen(app: app)
    }

    func goToSocial() throws -> SocialScreen {
        try open(row: "Social Row")
        return try SocialScreen(app: app)
    }

    func goToBlazeCampaigns() throws -> BlazeCampaignsScreen {
        try open(row: "Blaze Row")
        return try BlazeCampaignsScreen(app: app)
    }

    func goToActivityLog() throws -> ActivityLogScreen {
        try open(row: "Activity Log Row")
        return try ActivityLogScreen(app: app)
    }

    func goToUsers() throws -> UsersScreen {
        try open(row: "Users Row")
        return try UsersScreen(app: app)
    }

    func goToThemes() throws -> ThemesScreen {
        try open(row: "Themes Row")
        return try ThemesScreen(app: app)
    }

    func goToMenus() throws -> MenusScreen {
        try open(row: "Menus Row")
        return try MenusScreen(app: app)
    }

    func goToDomains() throws -> DomainsScreen {
        try open(row: "Domains Row")
        return try DomainsScreen(app: app)
    }

    func goToSiteSettings() throws -> SiteSettingsScreen {
        try open(row: "Settings Row")
        return try SiteSettingsScreen(app: app)
    }

    /// Each row's identifier is on a button inside its cell, or on a static text in an iPad's
    /// sidebar list. The list only creates the rows near the screen, so a row further down doesn't
    /// exist until it's scrolled to.
    private func open(row identifier: String) throws {
        try waitForScreen()
        let row = list.descendants(matching: .any).matching(identifier: identifier).firstMatch
        try scroll(to: row, in: list, waitsForExistence: false)
        row.tap()
    }
}

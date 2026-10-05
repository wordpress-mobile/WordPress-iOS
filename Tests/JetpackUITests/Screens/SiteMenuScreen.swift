import XCTest

/// The full site menu, opened from My Site's "More" row.
final class SiteMenuScreen: ScreenObject {
    private let tableGetter: ElementGetter = {
        $0.tables["Blog Details Table"]
    }

    var table: XCUIElement { tableGetter(app) }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [tableGetter], app: app)
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

    private func open(row identifier: String) throws {
        let row = table.cells[identifier]
        try scroll(to: row, in: table)
        row.tap()
    }
}

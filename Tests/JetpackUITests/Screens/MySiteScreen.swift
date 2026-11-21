import XCTest

/// The home screen for the selected site.
final class MySiteScreen: ScreenObject {
    private let contentGetter: ElementGetter = {
        $0.otherElements["my_site"]
    }

    private let createButtonGetter: ElementGetter = {
        $0.buttons["floatingCreateButton"]
    }

    /// The scroll view holding the header, the quick actions and the dashboard cards.
    var content: XCUIElement { contentGetter(app) }
    var createButton: XCUIElement { createButtonGetter(app) }
    var switchSiteButton: XCUIElement { app.buttons["switch-site-button"] }
    var siteTitle: XCUIElement { app.buttons["site-title-button"] }
    var siteURL: XCUIElement { app.buttons["site-url-button"] }

    /// Signing in syncs the account's sites before My Site appears, so this waits longer than
    /// most screens by default.
    ///
    /// The screen is identified by its container rather than its header, because the header
    /// scrolls out of view with the content.
    init(app: XCUIApplication, waitTimeout: TimeInterval = 60) throws {
        let expectedElementGetters = [contentGetter, createButtonGetter]
        try super.init(expectedElementGetters: expectedElementGetters, app: app, waitTimeout: waitTimeout)
    }

    func goToCreateSheet() throws -> ActionSheetComponent {
        try tap(createButton)
        return try ActionSheetComponent(app: app)
    }

    func goToNewPost() throws -> EditorScreen {
        try goToCreateSheet()
            .goToBlogPost()
    }

    func goToSitePicker() throws -> SitePickerScreen {
        try tap(switchSiteButton, until: app.navigationBars["My Sites"])
        return try SitePickerScreen(app: app)
    }

    // MARK: - Quick Actions

    // My Site is often the first screen a test taps after a launch, so each of these taps until
    // its screen appears. See `tap(_:until:)`.

    func goToStats() throws -> StatsScreen {
        try tap(app.cells["quick_actions_stats"], until: app.otherElements["stats-dashboard"])
        return try StatsScreen(app: app)
    }

    func goToPosts() throws -> PostsScreen {
        try tap(app.cells["quick_actions_posts"], until: app.tables["PostsTable"])
        return try PostsScreen(app: app)
    }

    func goToPages() throws -> PagesScreen {
        try tap(app.cells["quick_actions_pages"], until: app.tables["PagesTable"])
        return try PagesScreen(app: app)
    }

    func goToMedia() throws -> MediaScreen {
        try tap(app.cells["quick_actions_media"], until: app.navigationBars.staticTexts["Media"])
        return try MediaScreen(app: app)
    }

    func goToSiteMenu() throws -> SiteMenuScreen {
        try tap(app.cells["quick_actions_more"], until: app.collectionViews["Blog Details Table"])
        return try SiteMenuScreen(app: app)
    }
}

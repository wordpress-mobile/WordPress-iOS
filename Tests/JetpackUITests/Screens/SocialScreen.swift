import XCTest

/// The site's social media connections.
final class SocialScreen: ScreenObject {
    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [Self.navigationBarTitle("Social")], app: app)
    }

    /// The first connected account. The list also has a button that connects a new one, which
    /// is there before the accounts have loaded, so "the first row" isn't enough to find one.
    private var firstConnection: XCUIElement {
        app.collectionViews.firstMatch.cells.buttons
            .matching(NSPredicate(format: "label != 'Connect a New Account'"))
            .firstMatch
    }

    func goToFirstConnection() throws -> SocialConnectionScreen {
        try tapFirst(firstConnection, named: "social connections")
        return try SocialConnectionScreen(app: app)
    }
}

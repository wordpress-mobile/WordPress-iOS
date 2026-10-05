import XCTest

/// The site's social media connections.
final class SocialScreen: ScreenObject {
    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [Self.navigationBarTitle("Social")], app: app)
    }

    func goToFirstConnection() throws -> SocialConnectionScreen {
        try tapFirst(firstRow(in: app.collectionViews.firstMatch), named: "social connections")
        return try SocialConnectionScreen(app: app)
    }
}

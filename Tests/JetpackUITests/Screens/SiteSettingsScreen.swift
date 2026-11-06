import XCTest

/// The site's settings.
final class SiteSettingsScreen: ScreenObject {
    private let tableGetter: ElementGetter = {
        $0.tables["siteSettingsTable"]
    }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [tableGetter, Self.navigationBarTitle("Settings")], app: app)
    }
}

import XCTest

/// The theme browser.
final class ThemesScreen: ScreenObject {
    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [Self.navigationBarTitle("Themes")], app: app)
    }
}

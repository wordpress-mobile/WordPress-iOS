import XCTest

/// The site's navigation menus editor.
final class MenusScreen: ScreenObject {
    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [Self.navigationBarTitle("Menus")], app: app)
    }
}

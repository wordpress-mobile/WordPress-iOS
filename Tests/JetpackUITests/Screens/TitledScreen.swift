import XCTest

/// A pushed screen with nothing to identify it but its title.
final class TitledScreen: ScreenObject {
    init(title: String, app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [Self.navigationBarTitle(title)], app: app)
    }
}

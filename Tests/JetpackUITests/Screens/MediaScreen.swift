import XCTest

/// The site's media library.
final class MediaScreen: ScreenObject {
    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [Self.navigationBarTitle("Media")], app: app)
    }
}

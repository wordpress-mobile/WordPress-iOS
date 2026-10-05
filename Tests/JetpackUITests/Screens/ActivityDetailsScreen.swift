import XCTest

/// The details of one activity log event.
final class ActivityDetailsScreen: ScreenObject {
    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [Self.navigationBarTitle("Event")], app: app)
    }
}

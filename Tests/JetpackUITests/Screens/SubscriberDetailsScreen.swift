import XCTest

/// The details of one subscriber.
final class SubscriberDetailsScreen: ScreenObject {
    private let contentGetter: ElementGetter = {
        $0.scrollViews["subscriber-details"]
    }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [contentGetter], app: app)
    }
}

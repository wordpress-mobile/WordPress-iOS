import XCTest

/// The in-app browser showing a post as it appears on the site.
final class WebPreviewScreen: ScreenObject {
    private let dismissButtonGetter: ElementGetter = {
        $0.buttons["Dismiss"]
    }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [dismissButtonGetter, { $0.webViews.firstMatch }], app: app)
    }

    @discardableResult
    func dismiss() throws -> StatsScreen {
        dismissButtonGetter(app).tap()
        return try StatsScreen(app: app)
    }
}

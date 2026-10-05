import XCTest

/// The sheet for choosing which shortcuts and cards My Site shows.
final class PersonalizeHomeScreen: ScreenObject {
    private let navigationBarGetter: ElementGetter = {
        $0.navigationBars["Personalize Home Screen"]
    }

    private let closeButtonGetter: ElementGetter = {
        $0.navigationBars["Personalize Home Screen"].buttons["xmark"]
    }

    var closeButton: XCUIElement { closeButtonGetter(app) }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [navigationBarGetter, closeButtonGetter], app: app)
    }

    @discardableResult
    func close() throws -> MySiteScreen {
        closeButton.tap()
        return try MySiteScreen(app: app)
    }
}

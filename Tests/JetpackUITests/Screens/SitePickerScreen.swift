import XCTest

/// The list of the account's sites, for switching the selected site.
final class SitePickerScreen: ScreenObject {
    private let navigationBarGetter: ElementGetter = {
        $0.navigationBars["My Sites"]
    }

    private let closeButtonGetter: ElementGetter = {
        $0.buttons["my-sites-cancel-button"]
    }

    var closeButton: XCUIElement { closeButtonGetter(app) }

    func site(named name: String) -> XCUIElement {
        app.staticTexts[name]
    }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [navigationBarGetter, closeButtonGetter], app: app)
    }

    @discardableResult
    func close() throws -> MySiteScreen {
        closeButton.tap()
        return try MySiteScreen(app: app)
    }
}

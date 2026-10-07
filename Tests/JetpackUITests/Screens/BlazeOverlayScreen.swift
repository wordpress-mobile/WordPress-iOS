import XCTest

/// The sheet introducing Blaze, shown before any campaign is created.
final class BlazeOverlayScreen: ScreenObject {
    private let navigationBarGetter: ElementGetter = {
        $0.navigationBars["WordPress.BlazeOverlayView"]
    }

    private let closeButtonGetter: ElementGetter = {
        $0.navigationBars["WordPress.BlazeOverlayView"].buttons["close-button"]
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

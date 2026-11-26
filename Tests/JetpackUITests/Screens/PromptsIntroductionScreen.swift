import XCTest

/// The sheet introducing blogging prompts.
final class PromptsIntroductionScreen: ScreenObject {
    private let navigationBarGetter: ElementGetter = {
        $0.navigationBars["Introducing Blogging Prompts"]
    }

    private let closeButtonGetter: ElementGetter = {
        $0.navigationBars["Introducing Blogging Prompts"].buttons["close-button"]
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

import XCTest

/// The About sheet: links to rate and share the app, its blog and the legal notices.
final class AboutScreen: ScreenObject {
    private let closeButtonGetter: ElementGetter = {
        $0.buttons["Close"]
    }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [{ $0.staticTexts["Rate Us"] }, closeButtonGetter], app: app)
    }

    func row(_ title: String) -> XCUIElement {
        app.staticTexts[title]
    }

    func goToLegal() throws -> TitledScreen {
        try tap(row("Legal and More"))
        return try TitledScreen(title: "Legal and More", app: app)
    }

    @discardableResult
    func close() throws -> MeScreen {
        closeButtonGetter(app).tap()
        return try MeScreen(app: app)
    }
}

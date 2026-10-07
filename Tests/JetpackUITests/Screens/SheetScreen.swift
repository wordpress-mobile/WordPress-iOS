import XCTest

/// A sheet identified by its navigation bar, with a button in the bar that dismisses it.
final class SheetScreen: ScreenObject {
    private let title: String
    private let dismissButton: String

    /// - Parameters:
    ///   - title: The identifier of the sheet's navigation bar, which is its title.
    ///   - dismissButton: The title of the bar button that dismisses the sheet.
    init(title: String, dismissButton: String, app: XCUIApplication) throws {
        self.title = title
        self.dismissButton = dismissButton
        try super.init(expectedElementGetters: [{ $0.navigationBars[title] }], app: app)
    }

    func dismiss() {
        app.navigationBars[title].buttons[dismissButton].tap()
    }
}

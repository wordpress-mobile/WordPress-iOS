import XCTest

/// The WordPress.com account's settings.
final class AccountSettingsScreen: ScreenObject {
    /// The rows that push a screen for editing one setting. Each is titled the same as its screen.
    enum Setting: String, CaseIterable {
        case username = "Username"
        case email = "Email"
        case changePassword = "Change Password"
        case webAddress = "Web Address"
    }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [Self.navigationBarTitle("Account Settings")], app: app)
    }

    /// The row for a setting. It shows the setting's value beside its title.
    func row(_ title: String) -> XCUIElement {
        app.tables.cells[title]
    }

    func goTo(_ setting: Setting) throws -> TitledScreen {
        try tap(row(setting.rawValue))
        return try TitledScreen(title: setting.rawValue, app: app)
    }

    func goToPrimarySitePicker() throws -> SheetScreen {
        try tap(row("Primary Site"))
        return try SheetScreen(title: "Primary Site", dismissButton: "Cancel", app: app)
    }
}

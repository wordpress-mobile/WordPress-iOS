import XCTest

/// The Me tab: the account, its settings and the app's settings.
final class MeScreen: ScreenObject {
    private let tableGetter: ElementGetter = {
        $0.tables["Me Table"]
    }

    var table: XCUIElement { tableGetter(app) }
    var displayName: XCUIElement { app.staticTexts["Display Name"] }
    var username: XCUIElement { app.staticTexts["Username"] }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [tableGetter], app: app)
    }

    func goToMyProfile() throws -> GravatarProfileScreen {
        try open(table.cells["myProfile"])
        return try GravatarProfileScreen(app: app)
    }

    func goToAccountSettings() throws -> AccountSettingsScreen {
        try open(table.cells["accountSettings"])
        return try AccountSettingsScreen(app: app)
    }

    func goToAppSettings() throws -> AppSettingsScreen {
        try open(table.cells["appSettings"])
        return try AppSettingsScreen(app: app)
    }

    func goToHelp() throws -> HelpScreen {
        // This row has no identifier.
        try open(table.cells.containing(.staticText, identifier: "Help & Support").firstMatch)
        return try HelpScreen(app: app)
    }

    func goToAbout() throws -> AboutScreen {
        try open(table.cells["About"])
        return try AboutScreen(app: app)
    }

    private func open(_ row: XCUIElement) throws {
        try scroll(to: row, in: table)
        row.tap()
    }
}

import XCTest

/// Help & Support: the ways to reach support, and the app's version and logs.
final class HelpScreen: ScreenObject {
    private let helpCenterRowGetter: ElementGetter = {
        $0.cells["help-center-link-button"]
    }

    var contactSupportRow: XCUIElement { app.cells["contact-support-button"] }
    var ticketsRow: XCUIElement { app.cells["my-tickets-button"] }
    var contactEmailRow: XCUIElement { app.cells["set-contact-email-button"] }
    var versionRow: XCUIElement { app.cells["Version"] }
    var logsRow: XCUIElement { app.cells["activity-logs-button"] }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [Self.navigationBarTitle("Help"), helpCenterRowGetter], app: app)
    }

    func goToLogs() throws -> TitledScreen {
        try tap(logsRow)
        return try TitledScreen(title: "Activity Logs", app: app)
    }
}

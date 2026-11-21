import XCTest

/// Help & Support: the ways to reach support, and the app's version and logs.
final class HelpScreen: ScreenObject {
    private let versionRowGetter: ElementGetter = {
        $0.cells["Version"]
    }

    var helpCenterRow: XCUIElement { app.cells["help-center-link-button"] }
    var contactSupportRow: XCUIElement { app.cells["contact-support-button"] }
    var ticketsRow: XCUIElement { app.cells["my-tickets-button"] }
    var contactEmailRow: XCUIElement { app.cells["set-contact-email-button"] }
    var forumPromptRow: XCUIElement { app.cells["visit-wordpress-forums-prompt"] }
    var forumButtonRow: XCUIElement { app.cells["visit-wordpress-forums-button"] }
    var versionRow: XCUIElement { versionRowGetter(app) }
    var logsRow: XCUIElement { app.cells["activity-logs-button"] }

    /// The rows for reaching support. A build with the app's Zendesk credentials offers Zendesk
    /// support. Any other build, such as one made on CI, offers the community forum instead.
    var supportRows: [XCUIElement] {
        helpCenterRow.exists
            ? [helpCenterRow, contactSupportRow, ticketsRow, contactEmailRow]
            : [forumPromptRow, forumButtonRow]
    }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [Self.navigationBarTitle("Help"), versionRowGetter], app: app)
    }

    func goToLogs() throws -> TitledScreen {
        try tap(logsRow)
        return try TitledScreen(title: "Activity Logs", app: app)
    }
}

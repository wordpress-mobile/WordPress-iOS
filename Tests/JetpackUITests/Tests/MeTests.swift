import XCTest

/// Covers the Me tab: the account, its settings, the app's settings, help and About.
///
/// Runs on the fixtures backend, whose account never changes, so the tests assert on what the
/// screens show. They only read, so they share one sign-in.
final class MeTests: JetpackUITestCase {
    override class var backend: Backend { .fixtures }
    override class var resetsAppBeforeEachTest: Bool { false }

    private func me() throws -> MeScreen {
        try MySiteScreen(app: app)
            .goToMe()
    }

    func testAccount() throws {
        let me = try me()

        XCTAssertEqual(me.displayName.label, "e2eflowtestingmobile")
        XCTAssertEqual(me.username.label, "@e2eflowtestingmobile")
    }

    func testMyProfile() throws {
        try me()
            .goToMyProfile()
            .waitForScreen()
            .done()
    }

    func testAccountSettings() throws {
        let settings = try me()
            .goToAccountSettings()

        let values = [
            "Username": "e2eflowtestingmobile",
            "Email": "e2eflowtestingmobile@example.com",
            "Primary Site": "Tri-County Real Estate"
        ]
        for (row, value) in values {
            XCTAssertTrue(settings.row(row).staticTexts[value].pollForExistence(timeout: 10), "\(row) isn't \(value)")
        }
    }

    func testAccountSettingsScreens() throws {
        let settings = try me()
            .goToAccountSettings()

        for setting in AccountSettingsScreen.Setting.allCases {
            try settings.goTo(setting).goBack()
            try settings.waitForScreen()
        }

        try settings.goToPrimarySitePicker().dismiss()
        try settings.waitForScreen()
    }

    func testAppSettingsScreens() throws {
        let settings = try me()
            .goToAppSettings()

        for section in AppSettingsScreen.Section.allCases {
            try settings.goTo(section).goBack()
            try settings.waitForScreen()
        }
    }

    func testHelp() throws {
        let help = try me()
            .goToHelp()
            .waitForScreen()

        for row in [help.contactSupportRow, help.ticketsRow, help.contactEmailRow, help.versionRow] {
            XCTAssertTrue(row.pollForExistence(timeout: 10), "\(row) is missing")
        }

        try help.goToLogs().goBack()
        try help.waitForScreen()
    }

    func testAbout() throws {
        let about = try me()
            .goToAbout()
            .waitForScreen()

        for row in ["Share with Friends", "Blog", "Legal and More", "Automattic Family", "Work With Us"] {
            XCTAssertTrue(about.row(row).pollForExistence(timeout: 10), "\(row) is missing")
        }

        try about.goToLegal().goBack()
        try about.close()
    }
}

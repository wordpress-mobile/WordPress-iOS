import XCTest

/// Covers the cards on My Site's dashboard: what each card, its header, its rows and its menu open.
///
/// These tests only read, so they share one sign-in. The ones that open the editor close it
/// without making a change.
final class DashboardCardTests: JetpackUITestCase {
    override class var resetsAppBeforeEachTest: Bool { false }

    // MARK: - Prompts

    func testPromptsCardResponses() throws {
        try MySiteScreen(app: app)
            .goToPromptResponsesFromDashboardCard()
            .waitForScreen()
    }

    func testPromptsCardMenuPromptsList() throws {
        try MySiteScreen(app: app)
            .goToPromptsListFromDashboardCardMenu()
            .waitForScreen()
    }

    func testPromptsCardMenuLearnMore() throws {
        try MySiteScreen(app: app)
            .goToPromptsIntroductionFromDashboardCardMenu()
            .waitForScreen()
            .close()
    }

    // MARK: - Blaze

    func testBlazeCard() throws {
        try MySiteScreen(app: app)
            .goToBlazeFromDashboardCard()
            .waitForScreen()
            .close()
    }

    func testBlazeCardMenuLearnMore() throws {
        try MySiteScreen(app: app)
            .goToBlazeFromDashboardCardMenu()
            .waitForScreen()
            .close()
    }

    // MARK: - Today's Stats

    func testTodaysStatsCard() throws {
        try MySiteScreen(app: app)
            .goToStatsFromDashboardCard()
            .waitForScreen()
    }

    // MARK: - Draft Posts

    func testDraftPostsCardHeader() throws {
        try MySiteScreen(app: app)
            .goToDraftsFromDashboardCard()
            .waitForScreen()
            .waitForSelection(of: .drafts)
    }

    func testDraftPostsCardMenuViewAll() throws {
        try MySiteScreen(app: app)
            .goToDraftsFromDashboardCardMenu()
            .waitForScreen()
            .waitForSelection(of: .drafts)
    }

    func testDraftPostsCardRow() throws {
        try MySiteScreen(app: app)
            .goToFirstDraftFromDashboardCard()
            .waitForScreen()
            .closeAndDiscardChanges()
    }

    // MARK: - Pages

    func testPagesCardHeader() throws {
        try MySiteScreen(app: app)
            .goToPagesFromDashboardCard()
            .waitForScreen()
    }

    func testPagesCardMenuAllPages() throws {
        try MySiteScreen(app: app)
            .goToPagesFromDashboardCardMenu()
            .waitForScreen()
    }

    func testPagesCardRow() throws {
        try MySiteScreen(app: app)
            .goToFirstPageFromDashboardCard()
            .waitForScreen()
            .closeAndDiscardChanges()
    }

    // MARK: - Activity Log

    func testActivityLogCardHeader() throws {
        try MySiteScreen(app: app)
            .goToActivityLogFromDashboardCard()
            .waitForScreen()
    }

    func testActivityLogCardMenuAllActivity() throws {
        try MySiteScreen(app: app)
            .goToActivityLogFromDashboardCardMenu()
            .waitForScreen()
    }

    func testActivityLogCardRow() throws {
        try MySiteScreen(app: app)
            .goToFirstActivityFromDashboardCard()
            .waitForScreen()
    }

    // MARK: - Personalize

    func testPersonalizeCard() throws {
        try MySiteScreen(app: app)
            .goToPersonalizeHomeScreen()
            .waitForScreen()
            .close()
    }
}

@testable import WordPress
@testable import WordPressKit
import Testing

struct ActivityStringFormattingTests {

    // MARK: - actorName

    @Test func actorNameReturnsDisplayName() {
        let actor = ActivityActor(dictionary: ["name": "Alice", "type": "Person", "role": "administrator"])
        #expect(ActivityStringFormatting.actorName(for: actor) == "Alice")
    }

    @Test func actorNameReturnsUnknownUserWhenEmpty() {
        let actor = ActivityActor(dictionary: ["name": "", "type": "Person", "role": "editor"])
        #expect(ActivityStringFormatting.actorName(for: actor) == Activity.Strings.unknownUser)
    }

    @Test func actorNameReturnsUnknownUserWhenMissing() {
        let actor = ActivityActor(dictionary: ["type": "Person", "role": "editor"])
        #expect(ActivityStringFormatting.actorName(for: actor) == Activity.Strings.unknownUser)
    }

    // MARK: - actorRole

    @Test func actorRoleReturnsCapitalizedRole() {
        let actor = ActivityActor(dictionary: ["name": "Alice", "type": "Person", "role": "administrator"])
        #expect(ActivityStringFormatting.actorRole(for: actor) == "Administrator")
    }

    @Test func actorRoleFallsBackToTypeWhenRoleEmpty() {
        let actor = ActivityActor(dictionary: ["name": "Jetpack", "type": "Application", "role": ""])
        #expect(ActivityStringFormatting.actorRole(for: actor) == "Application")
    }

    @Test func actorRoleFallsBackToTypeWhenRoleMissing() {
        let actor = ActivityActor(dictionary: ["name": "Jetpack", "type": "Application"])
        #expect(ActivityStringFormatting.actorRole(for: actor) == "Application")
    }

    // MARK: - botName

    @Test func botNameForMCPAgent() {
        let actor = ActivityActor(dictionary: [
            "name": "bot-user",
            "type": "Person",
            "role": "administrator",
            "is_mcp_agent": true,
            "mcp_client": "Claude"
        ])
        #expect(ActivityStringFormatting.botName(for: actor) == "via Claude")
    }

    @Test func botNameForNonMCPActor() {
        let actor = ActivityActor(dictionary: ["name": "Alice", "type": "Person", "role": "editor"])
        #expect(ActivityStringFormatting.botName(for: actor) == nil)
    }

    @Test func botNameForMCPAgentWithEmptyClient() {
        let actor = ActivityActor(dictionary: [
            "name": "bot-user",
            "type": "Person",
            "role": "administrator",
            "is_mcp_agent": true,
            "mcp_client": ""
        ])
        #expect(ActivityStringFormatting.botName(for: actor) == nil)
    }

    @Test func botNameForMCPAgentWithNoClient() {
        let actor = ActivityActor(dictionary: [
            "name": "bot-user",
            "type": "Person",
            "role": "administrator",
            "is_mcp_agent": true
        ])
        #expect(ActivityStringFormatting.botName(for: actor) == nil)
    }
}

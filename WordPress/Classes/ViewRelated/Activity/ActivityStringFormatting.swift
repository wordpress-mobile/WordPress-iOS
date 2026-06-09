import Foundation
import WordPressData
import WordPressKit

struct ActivityStringFormatting {
    private static let agentString = NSLocalizedString(
        "activityDetail.section.agent",
        value: "via %1$@",
        comment: "Shows the MCP client used for an activity. %1$@ is the MCP client name (e.g. Claude)."
    )

    static func actorName(for actor: ActivityActor) -> String {
        actor.displayName.isEmpty ? Activity.Strings.unknownUser : actor.displayName
    }

    static func actorRole(for actor: ActivityActor) -> String {
        actor.role.isEmpty ? actor.type.localizedCapitalized : actor.role.localizedCapitalized
    }

    static func botName(for actor: ActivityActor) -> String? {
        guard actor.isMCPAgent, let mcpClient = actor.mcpClient, !mcpClient.isEmpty else {
            return nil
        }

        return String(format: Self.agentString, mcpClient)
    }
}

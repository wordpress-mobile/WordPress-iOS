import Foundation
import WordPressData

struct ActivityStringFormatting {
    private static let agentString = NSLocalizedString(
        "activityDetail.section.agent",
        value: "via %@",
        comment: "Explanation of the actor chain for a given operation (ex: via Claude Code)"
    )

    private static let combinedAgentString = NSLocalizedString(
        "activityDetail.section.actorAndAgent",
        value: "%@ via %@",
        comment: "Explanation of the actor chain for a given operation (ex: Bob via Claude Code)"
    )

    static func actorName(for actor: ActivityActor) -> String {
        actor.displayName.isEmpty ? Activity.Strings.unknownUser : actor.displayName
    }

    static func actorRole(for actor: ActivityActor) -> String {
        actor.role.isEmpty ? actor.type.localizedCapitalized : actor.role.localizedCapitalized
    }

    static func actorDescription(for actor: ActivityActor) -> String {
        if actor.isMCPAgent, let mcpClient = actor.mcpClient, !mcpClient.isEmpty {
            return String(format: Self.combinedAgentString, actorRole(for: actor), mcpClient)
        } else {
            return actorRole(for: actor)
        }
    }

    static func botName(for actor: ActivityActor) -> String? {
        guard actor.isMCPAgent, let mcpClient = actor.mcpClient, !mcpClient.isEmpty else {
            return nil
        }

        return String(format: Self.agentString, mcpClient)
    }
}

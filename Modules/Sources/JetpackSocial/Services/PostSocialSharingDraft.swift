import Foundation
import WordPressAPI
import WordPressAPIInternal

public struct PostSocialSharingDraft: Equatable, Hashable, Sendable {
    public struct Connection: Identifiable, Equatable, Hashable, Sendable {
        public var id: String
        public var enabled: Bool

        public init(id: String, enabled: Bool) {
            self.id = id
            self.enabled = enabled
        }
    }

    public var customMessage: String?
    public var connectionsByID: [String: Connection]?

    // TODO: per-connection customization (`_wpas_customize_per_network`) —
    // extend to include per-connection message / attached_media / media_source
    // once the backend paid feature lands.

    public init(customMessage: String? = nil, connectionsByID: [String: Connection]? = nil) {
        self.customMessage = customMessage
        self.connectionsByID = connectionsByID
    }
}

extension PostSocialSharingDraft {
    /// Parses the relevant fields off a fetched post into a draft. Connections
    /// come from the post's `additional_fields` blob (where Jetpack registers
    /// `jetpack_publicize_connections` as a top-level REST field); the custom
    /// message comes from `meta.jetpack_publicize_message`. Unknown or missing
    /// keys collapse to defaults.
    public init(fromPostAdditionalFields fields: WpAdditionalFields?, meta: PostMeta?) {
        self.init(
            customMessage: meta?.publicizeMessage,
            connectionsByID: fields?.publicizeConnectionsByID
        )
    }

    public func isEnabled(connectionID: String) -> Bool {
        connectionsByID?[connectionID]?.enabled ?? true
    }

    public mutating func setEnabled(
        _ enabled: Bool,
        for connection: SocialConnection,
        availableConnections: [SocialConnection]
    ) {
        var connections = materializedConnectionsByID(availableConnections: availableConnections)
        connections[connection.id] = Connection(id: connection.id, enabled: enabled)
        connectionsByID = connections
    }

    public mutating func addConnection(
        _ connection: SocialConnection,
        availableConnections: [SocialConnection]
    ) {
        var connections = materializedConnectionsByID(availableConnections: availableConnections)
        connections[connection.id] = Connection(id: connection.id, enabled: true)
        connectionsByID = connections
    }

    private func materializedConnectionsByID(
        availableConnections: [SocialConnection]
    ) -> [String: Connection] {
        var materializedConnectionsByID: [String: Connection] = [:]
        for connection in availableConnections {
            materializedConnectionsByID[connection.id] =
                connectionsByID?[connection.id] ?? Connection(id: connection.id, enabled: true)
        }
        return materializedConnectionsByID
    }
}

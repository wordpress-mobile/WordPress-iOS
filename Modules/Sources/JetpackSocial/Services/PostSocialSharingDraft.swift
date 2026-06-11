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

    /// Suffixes (keyring connection IDs or service names) of truthy legacy
    /// `_wpas_skip_*` rows found in the post's metadata. The backend ORs every
    /// skip scheme at publish time, so a connection must render as disabled
    /// when any of its legacy rows is set, even if its connection-keyed row
    /// says otherwise. Populated only by the v1.1 metadata bridge; stays empty
    /// on the core REST path, where the server resolves legacy rows itself.
    public var legacyDisabledKeys: Set<String>

    // TODO: per-connection customization (`_wpas_customize_per_network`) —
    // extend to include per-connection message / attached_media / media_source
    // once the backend paid feature lands.

    public init(
        customMessage: String? = nil,
        connectionsByID: [String: Connection]? = nil,
        legacyDisabledKeys: Set<String> = []
    ) {
        self.customMessage = customMessage
        self.connectionsByID = connectionsByID
        self.legacyDisabledKeys = legacyDisabledKeys
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

    /// Only a building block for `isEnabled(connection:)`: legacy skip rows
    /// are keyed by keyring ID or service name, which a bare connection ID
    /// cannot be matched against.
    private func isEnabled(connectionID: String) -> Bool {
        connectionsByID?[connectionID]?.enabled ?? true
    }

    /// Mirrors the backend publish-time gate: a connection is disabled when
    /// its explicit entry says so or when any of its legacy-format skip rows
    /// (keyring-keyed or service-keyed) is set.
    public func isEnabled(connection: SocialConnection) -> Bool {
        !isLegacyDisabled(connection) && isEnabled(connectionID: connection.id)
    }

    public mutating func setEnabled(
        _ enabled: Bool,
        for connection: SocialConnection,
        availableConnections: [SocialConnection]
    ) {
        var connections = materializedConnectionsByID(availableConnections: availableConnections)
        if enabled {
            // A legacy key covers every connection on its keyring (or service),
            // so before clearing the keys shared with this connection, pin the
            // other legacy-disabled connections to explicit OFF entries. Without
            // this, enabling one Facebook page would silently re-enable the
            // other pages under the same login.
            for other in availableConnections
            where other.id != connection.id && isLegacyDisabled(other) {
                connections[other.id] = Connection(id: other.id, enabled: false)
            }
            if let keyringID = connection.keyringConnectionID {
                legacyDisabledKeys.remove(keyringID)
            }
            legacyDisabledKeys.remove(connection.serviceName)
        }
        connections[connection.id] = Connection(id: connection.id, enabled: enabled)
        connectionsByID = connections
    }

    private func isLegacyDisabled(_ connection: SocialConnection) -> Bool {
        if let keyringID = connection.keyringConnectionID,
            legacyDisabledKeys.contains(keyringID)
        {
            return true
        }
        return legacyDisabledKeys.contains(connection.serviceName)
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

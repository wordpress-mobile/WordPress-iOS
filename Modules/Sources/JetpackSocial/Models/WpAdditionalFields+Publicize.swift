import Foundation
import WordPressAPI

private enum PublicizeAdditionalFieldKeys {
    static let connections = "jetpack_publicize_connections"
}

extension WpAdditionalFields {
    /// Parses the post-level Publicize connection state if the REST field was present.
    public var publicizeConnectionsByID: [String: PostSocialSharingDraft.Connection]? {
        guard keys().contains(PublicizeAdditionalFieldKeys.connections) else {
            return nil
        }

        var connectionsByID: [String: PostSocialSharingDraft.Connection] = [:]
        for entry in arrayValueForKey(key: PublicizeAdditionalFieldKeys.connections) ?? [] {
            guard case let .object(dict) = entry,
                case let .string(id)? = dict["connection_id"],
                case let .bool(enabled)? = dict["enabled"]
            else {
                continue
            }
            connectionsByID[id] = .init(id: id, enabled: enabled)
        }
        return connectionsByID
    }

    /// Returns a new `WpAdditionalFields` with the `jetpack_publicize_connections`
    /// key populated with the draft's explicit per-post connection state.
    public func addingPublicizeConnections(
        _ connectionsByID: [String: PostSocialSharingDraft.Connection]
    ) -> WpAdditionalFields {
        let entries: [JsonValue] = connectionsByID.values.sorted { $0.id < $1.id }.map { connection in
            .object([
                "connection_id": .string(connection.id),
                "enabled": .bool(connection.enabled)
            ])
        }
        return self.withValue(key: PublicizeAdditionalFieldKeys.connections, value: .array(entries))
    }
}

import Foundation
import WordPressAPI

extension WpAdditionalFields {
    /// Returns a new `WpAdditionalFields` with the `jetpack_publicize_connections`
    /// key populated for the given site connection IDs. Each entry encodes whether
    /// that connection is enabled for the post (i.e., absent from `disabled`).
    public func addingPublicizeConnections(_ ids: [String], disabled: Set<String>) -> WpAdditionalFields {
        let entries: [JsonValue] = ids.map { id in
            .object([
                "connection_id": .string(id),
                "enabled": .bool(!disabled.contains(id))
            ])
        }
        return self.withValue(key: "jetpack_publicize_connections", value: .array(entries))
    }
}

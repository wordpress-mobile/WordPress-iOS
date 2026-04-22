import Foundation
import WordPressAPI
import WordPressAPIInternal

public struct PostSocialSharingDraft: Equatable, Hashable, Sendable {
    public var customMessage: String?
    public var disabledConnectionIDs: Set<String>

    // TODO: per-connection customization (`_wpas_customize_per_network`) —
    // extend to include per-connection message / attached_media / media_source
    // once the backend paid feature lands.

    public init(customMessage: String? = nil, disabledConnectionIDs: Set<String> = []) {
        self.customMessage = customMessage
        self.disabledConnectionIDs = disabledConnectionIDs
    }
}

extension PostSocialSharingDraft {
    /// Parses the relevant fields off a fetched post into a draft. Connections
    /// come from the post's `additional_fields` blob (where Jetpack registers
    /// `jetpack_publicize_connections` as a top-level REST field); the custom
    /// message comes from `meta.jetpack_publicize_message`. Unknown or missing
    /// keys collapse to defaults.
    public init(fromPostAdditionalFields fields: WpAdditionalFields?, meta: PostMeta?) {
        var message: String? = nil
        var disabled: Set<String> = []

        // PostMeta only exposes the untyped `valueForKey`, so we still pattern
        // match the JsonValue here (unlike the WpAdditionalFields side below).
        if case let .string(text)? = meta?.valueForKey(key: "jetpack_publicize_message"), !text.isEmpty {
            message = text
        }

        let entries = fields?.arrayValueForKey(key: "jetpack_publicize_connections") ?? []
        for entry in entries {
            guard case let .object(dict) = entry,
                case let .string(id)? = dict["connection_id"],
                case let .bool(enabled)? = dict["enabled"],
                !enabled
            else {
                continue
            }
            disabled.insert(id)
        }

        self.init(customMessage: message, disabledConnectionIDs: disabled)
    }
}

import Foundation
import JetpackSocial
import WordPressData

/// Jetpack Social (Publicize) decides where a post gets shared at publish
/// time by reading the post's meta rows, not a dedicated API field. A
/// connection shares by default; a truthy "skip" row suppresses it. Three
/// generations of skip keys exist and the backend ORs them all, so any one
/// truthy row wins:
///
/// - `_wpas_skip_publicize_<connectionID>`: the current scheme, one row per
///   connection, written by every first-party client since mid-2023.
/// - `_wpas_skip_<keyringID>`: legacy. The keyring (OAuth token) ID is shared
///   by every connection under one external login, so one row covers them
///   all. Old posts still carry these, and they never expire or migrate.
/// - `_wpas_skip_<serviceName>`: the oldest scheme, one row per service.
///
/// Because of the OR, writing `_wpas_skip_publicize_<id> = 0` cannot
/// re-enable a connection whose legacy row is still truthy; the legacy row
/// itself must be zeroed. That asymmetry drives both directions of this
/// bridge: reading probes every key shape a connection's IDs could have
/// produced (mirroring `Publicize::get_filtered_connection_data()` in the
/// Jetpack plugin), and writing zeroes the legacy rows the user cleared.
/// `_wpas_mess` carries the optional custom share message.
enum SocialSharingMetadata {
    static let skipPrefix = "_wpas_skip_publicize_"
    static let legacySkipPrefix = "_wpas_skip_"
    static let messageKey: PostMetadataContainer.Key = "_wpas_mess"

    /// All social sharing entries: the message plus skip rows of every
    /// generation. Legacy rows must ride along in the upload set so that
    /// zeroed-out values actually reach the server.
    static func publicizeEntries(in container: PostMetadataContainer) -> [[String: Any]] {
        container.values.filter { entry in
            guard let key = entry["key"] as? String else {
                return false
            }
            // The skipPrefix check is redundant (legacySkipPrefix is its
            // prefix) but spelled out so the filter stays correct if the
            // constants ever diverge.
            return key == messageKey.rawValue
                || key.hasPrefix(skipPrefix)
                || key.hasPrefix(legacySkipPrefix)
        }
    }

    /// Suffix (keyring connection ID or service name) of a legacy-format skip
    /// key, or nil for connection-keyed and unrelated keys.
    static func legacySkipSuffix(of key: String) -> String? {
        guard key.hasPrefix(legacySkipPrefix), !key.hasPrefix(skipPrefix) else {
            return nil
        }
        let suffix = String(key.dropFirst(legacySkipPrefix.count))
        return suffix.isEmpty ? nil : suffix
    }

    static func isDisabled(_ value: Any?) -> Bool {
        switch value {
        case let value as Bool:
            return value
        case let value as NSNumber:
            return value.boolValue
        case let value as String:
            return value == "1"
        default:
            return false
        }
    }
}

extension PostSocialSharingDraft {
    init(socialMetadata container: PostMetadataContainer) {
        let message = container.getString(for: SocialSharingMetadata.messageKey)
        var connectionsByID: [String: Connection] = [:]
        var legacyDisabledKeys: Set<String> = []
        for entry in SocialSharingMetadata.publicizeEntries(in: container) {
            guard let key = entry["key"] as? String else {
                continue
            }
            if key.hasPrefix(SocialSharingMetadata.skipPrefix) {
                let connectionID = String(key.dropFirst(SocialSharingMetadata.skipPrefix.count))
                guard !connectionID.isEmpty else {
                    continue
                }
                connectionsByID[connectionID] = Connection(
                    id: connectionID,
                    enabled: !SocialSharingMetadata.isDisabled(entry["value"])
                )
            } else if let suffix = SocialSharingMetadata.legacySkipSuffix(of: key),
                SocialSharingMetadata.isDisabled(entry["value"])
            {
                legacyDisabledKeys.insert(suffix)
            }
        }

        self.init(
            customMessage: message?.isEmpty == false ? message : nil,
            connectionsByID: connectionsByID.isEmpty ? nil : connectionsByID,
            legacyDisabledKeys: legacyDisabledKeys
        )
    }

    func applySocialMetadata(to container: inout PostMetadataContainer) {
        if let customMessage, !customMessage.isEmpty {
            container.setValue(customMessage, for: SocialSharingMetadata.messageKey)
        } else if container.entry(forKey: SocialSharingMetadata.messageKey) != nil {
            container.setValue("", for: SocialSharingMetadata.messageKey)
        }

        if let connectionsByID {
            for connection in connectionsByID.values {
                container.setValue(
                    connection.enabled ? "0" : "1",
                    for: PostMetadataContainer.Key(rawValue: "\(SocialSharingMetadata.skipPrefix)\(connection.id)")
                )
            }
        }

        // Writing the connection-keyed row alone cannot re-enable a connection:
        // the backend ORs every skip scheme, so a stale truthy legacy row keeps
        // suppressing the share. Zero out the legacy rows the user cleared this
        // session (their suffix left `legacyDisabledKeys` when the connection
        // was toggled on). Rows still in the set, including ones for unknown
        // keyrings, stay untouched.
        for entry in container.values {
            guard let key = entry["key"] as? String,
                let suffix = SocialSharingMetadata.legacySkipSuffix(of: key),
                !legacyDisabledKeys.contains(suffix),
                SocialSharingMetadata.isDisabled(entry["value"])
            else {
                continue
            }
            container.setValue("0", for: PostMetadataContainer.Key(rawValue: key))
        }
    }
}

enum PostSocialSharing {
    static func isEligible(for post: AbstractPost) -> Bool {
        post is Post && post.blog.dotComID != nil && post.blog.supports(.publicize)
    }
}

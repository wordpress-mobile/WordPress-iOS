import Foundation
import JetpackSocial
import WordPressData

enum SocialSharingMetadata {
    static let skipPrefix = "_wpas_skip_publicize_"
    static let messageKey: PostMetadataContainer.Key = "_wpas_mess"

    static func publicizeEntries(in container: PostMetadataContainer) -> [[String: Any]] {
        container.values.filter { entry in
            guard let key = entry["key"] as? String else {
                return false
            }
            return key == messageKey.rawValue || key.hasPrefix(skipPrefix)
        }
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
        let connectionsByID = SocialSharingMetadata.publicizeEntries(in: container)
            .reduce(
                into: [String: Connection]()
            ) { connectionsByID, entry in
                guard let key = entry["key"] as? String,
                    key.hasPrefix(SocialSharingMetadata.skipPrefix)
                else {
                    return
                }

                let connectionID = String(key.dropFirst(SocialSharingMetadata.skipPrefix.count))
                guard !connectionID.isEmpty else {
                    return
                }

                connectionsByID[connectionID] = Connection(
                    id: connectionID,
                    enabled: !SocialSharingMetadata.isDisabled(entry["value"])
                )
            }

        self.init(
            customMessage: message?.isEmpty == false ? message : nil,
            connectionsByID: connectionsByID.isEmpty ? nil : connectionsByID
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
    }
}

enum PostSocialSharing {
    static func isEligible(for post: AbstractPost) -> Bool {
        post is Post && post.blog.dotComID != nil && post.blog.supports(.publicize)
    }
}

extension PostService {
    typealias StringDictionary = [String: String]
    typealias Keys = Post.Constants

    // TODO: Move to Post.
    enum PublicizeMetadataSkipPrefix: String {
        case keyring = "_wpas_skip_"
        case connection = "_wpas_skip_publicize_"

        static func prefix(of key: String) -> PublicizeMetadataSkipPrefix? {
            guard key.hasPrefix(Self.keyring.rawValue) else {
                return nil
            }
            return key.hasPrefix(Self.connection.rawValue) ? .connection : .keyring
        }
    }

    /// RemotePost -> Post.
    /// TODO: Docs.
    @objc(disabledPublicizeConnectionsForPost:andMetadata:)
    func disabledPublicizeConnections(for post: AbstractPost?, metadata: [StringDictionary]?) -> [NSNumber: StringDictionary] {
        guard let post,
              let metadata else {
            return [:]
        }

        return metadata
            .filter { $0[Keys.publicizeKeyKey]?.hasPrefix(PublicizeMetadataSkipPrefix.keyring.rawValue) ?? false }
            .reduce(into: [NSNumber: StringDictionary]()) { partialResult, entry in
                guard let key = entry[Post.Constants.publicizeKeyKey] else {
                    return
                }

                func getConnectionID() -> Int? {
                    guard let prefix = PublicizeMetadataSkipPrefix.prefix(of: key) else {
                        return nil
                    }

                    switch prefix {
                    case .connection:
                        // If the key already uses the new format, then return the `connectionID` segment.
                        return Int(key.removingPrefix(PublicizeMetadataSkipPrefix.connection.rawValue))

                    case .keyring:
                        // If the key uses a keyring format, try to find an existing `PublicizeConnection` that
                        // matches the `keyringID`, and get its connectionID.
                        guard let connections = post.blog.connections as? Set<PublicizeConnection>,
                              let keyringID = Int(key.removingPrefix(PublicizeMetadataSkipPrefix.keyring.rawValue)) else {
                            return nil
                        }

                        return connections.first { $0.keyringConnectionID.intValue == keyringID }?.connectionID.intValue
                    }
                }

                // If the connectionID exists, then we'll use that as the dictionary key.
                if let connectionID = getConnectionID() {
                    partialResult[NSNumber(value: connectionID)] = entry
                    return
                }

                // Fall back to the previous implementation if the keyring is not found on the blog's connections.
                // The previous implementation only reads the `id` and `value`, and uses `keyringID` as the dictionary key.
                if let entryKeyringID = Int(key.removingPrefix(PublicizeMetadataSkipPrefix.keyring.rawValue)) {
                    var connectionDictionary = StringDictionary()
                    connectionDictionary[Keys.publicizeIdKey] = entry[Keys.publicizeIdKey]
                    connectionDictionary[Keys.publicizeValueKey] = entry[Keys.publicizeValueKey]
                    partialResult[NSNumber(value: entryKeyringID)] = connectionDictionary
                }
            }
    }

    // TODO: Docs.
    @objc(publicizeMetadataEntriesForPost:)
    func publicizeMetadataEntries(for post: Post?) -> [StringDictionary] {
        guard let post,
              let disabledConnectionsDictionary = post.disabledPublicizeConnections else {
            return []
        }

        return disabledConnectionsDictionary.map { (id: NSNumber, entry: StringDictionary) in
            // each entry should have a `value`, an optional `id`, and an optional `key`.
            // if the entry already has a key, then there's nothing to do.
            if let _ = entry[Keys.publicizeKeyKey] {
                return entry
            }

            // If the entry doesn't have an id, then this is likely using an old format.
            // The dictionary key is most likely a keyringID.
            var modifiedEntry = entry
            modifiedEntry[Keys.publicizeKeyKey] = "\(id)"
            return modifiedEntry
        }
    }

}

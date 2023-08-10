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

    /// Returns a dictionary format for the `Post`'s `disabledPublicizeConnection` property based on the given metadata.
    ///
    /// This will try to handle both Publicize skip key formats, `_wpas_skip_{keyringID}` and `_wpas_skip_publicize_{connectionID`.
    /// Different to the previous implementation, this will use the `PublicizeConnection`'s `connectionID` as the
    /// dictionary key if possible.
    ///
    /// There's a possibility that the keyringID obtained from remote doesn't match with any of the `PublicizeConnection`
    /// that's stored locally, perhaps due to the app being out of sync. In this case, we'll fall back to the previous
    /// implementation of using the `keyringID` as the dictionary key, and only storing `id` and `value`.
    ///
    /// - Parameters:
    ///   - post: The associated `Post` object. Optional because Obj-C shouldn't be trusted.
    ///   - metadata: The metadata dictionary for the post. Optional because Obj-C shouldn't be trusted.
    /// - Returns: A dictionary for the `Post`'s `disabledPublicizeConnections` property.
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
                    guard let prefixType = PublicizeMetadataSkipPrefix.prefix(of: key) else {
                        return nil
                    }

                    switch prefixType {
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

    /// Converts the `Post`'s `disabledPublicizeConnections` dictionary to metadata entries.
    ///
    /// - Parameter post: The associated `Post` object.
    /// - Returns: An array of metadata dictionaries representing the `Post`'s disabled connections.
    @objc(publicizeMetadataEntriesForPost:)
    func publicizeMetadataEntries(for post: Post?) -> [StringDictionary] {
        guard let post,
              let disabledConnectionsDictionary = post.disabledPublicizeConnections else {
            return []
        }

        return disabledConnectionsDictionary.compactMap { (id: NSNumber, entry: StringDictionary) in
            // The previous implementation didn't properly parse `_wpas_skip_publicize_` keys, causing it
            // to use 0 as the dictionary key. Although this will be ignored by the server, let's make sure
            // it's not sent to the remote any longer.
            guard id.intValue > 0 else {
                return nil
            }

            // Each entry should have a `value`, an optional `id`, and an optional `key`.
            // If the entry already has a key, then there's nothing to do.
            if let _ = entry[Keys.publicizeKeyKey] {
                return entry
            }

            // If the key doesn't exist, this means that the dictionary is still using the old format.
            // Try to add a key with the new format, ONLY if the metadata hasn't been synced to the remote.
            let keyMetadata: String = {
                guard entry[Keys.publicizeIdKey] == nil,
                      let connections = post.blog.connections as? Set<PublicizeConnection>,
                      let connection = connections.first(where: { $0.keyringConnectionID == id }) else {
                    // Fall back to the old keyring format.
                    return "\(PublicizeMetadataSkipPrefix.keyring.rawValue)\(id)"
                }

                return "\(PublicizeMetadataSkipPrefix.connection.rawValue)\(connection.connectionID)"
            }()

            return entry.merging([Keys.publicizeKeyKey: keyMetadata]) { _, newValue in newValue }
        }
    }

}

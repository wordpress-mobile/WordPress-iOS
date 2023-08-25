extension PostHelper {
    typealias StringDictionary = [String: String]
    typealias Keys = Post.Constants
    typealias SkipPrefix = Post.PublicizeMetadataSkipPrefix

    /// Returns a dictionary format for the `Post`'s `disabledPublicizeConnection` property based on the given metadata.
    ///
    /// This will try to handle both Publicize skip key formats, `_wpas_skip_{keyringID}` and `_wpas_skip_publicize_{connectionID`.
    ///
    /// There's a possibility that the `keyringID` obtained from remote doesn't match with any of the `PublicizeConnection`
    /// that's stored locally, perhaps due to the app being out of sync. In this case, we'll fall back to using the old format.
    ///
    /// - Parameters:
    ///   - post: The associated `Post` object. Optional because Obj-C shouldn't be trusted.
    ///   - metadata: The metadata dictionary for the post. Optional because Obj-C shouldn't be trusted.
    /// - Returns: A dictionary for the `Post`'s `disabledPublicizeConnections` property.
    @objc(disabledPublicizeConnectionsForPost:andMetadata:)
    static func disabledPublicizeConnections(for post: AbstractPost?, metadata: [[String: Any]]?) -> [NSNumber: StringDictionary] {
        guard let post, let metadata else {
            return [:]
        }

        return metadata
            .compactMap { $0 as? [String: String] }
            .filter { $0[Keys.publicizeKeyKey]?.hasPrefix(SkipPrefix.keyring.rawValue) ?? false }
            .reduce(into: [NSNumber: StringDictionary]()) { partialResult, entry in
                // every metadata entry should have a key.
                guard let key = entry[Keys.publicizeKeyKey] else {
                    return
                }

                func getDictionaryID() -> Int? {
                    guard let prefixType = SkipPrefix.prefix(of: key) else {
                        return nil
                    }

                    switch prefixType {
                    case .keyring:
                        return Int(key.removingPrefix(SkipPrefix.keyring.rawValue))

                    case .connection:
                        // If the key uses the new format, try to find an existing `PublicizeConnection` matching
                        // the connectionID, and return its keyringID.
                        let entryConnectionID = Int(key.removingPrefix(SkipPrefix.connection.rawValue))

                        guard let connections = post.blog.connections as? Set<PublicizeConnection>,
                              let connectionID = entryConnectionID,
                              let connection = connections.first(where: { $0.connectionID.intValue == connectionID }) else {
                            /// Otherwise, fall back to the connectionID extracted from the metadata key.
                            /// Note that entries with `connectionID` won't be detected by the Post's
                            /// `publicizeConnectionDisabledForKeyringID` method.
                            ///
                            /// However, the Publicize methods in `Post.swift` will attempt to update the key into
                            /// its `keyringID`, since the `PublicizeConnection` object is guaranteed to exist.
                            return entryConnectionID
                        }

                        return connection.keyringConnectionID.intValue
                    }
                }

                if let id = getDictionaryID() {
                    partialResult[NSNumber(value: id)] = entry
                }
            }
    }

    /// Converts the `Post`'s `disabledPublicizeConnections` dictionary to metadata entries.
    ///
    /// - Parameter post: The associated `Post` object.
    /// - Returns: An array of metadata dictionaries representing the `Post`'s disabled connections.
    @objc(publicizeMetadataEntriesForPost:)
    static func publicizeMetadataEntries(for post: Post?) -> [StringDictionary] {
        guard let post,
              let disabledConnectionsDictionary = post.disabledPublicizeConnections else {
            return []
        }

        return disabledConnectionsDictionary.compactMap { (keyringID: NSNumber, entry: StringDictionary) in
            // The previous implementation didn't properly parse `_wpas_skip_publicize_` keys, causing it
            // to use 0 as the dictionary key. Although this will be ignored by the server, let's make sure
            // it's not sent to the remote any longer.
            guard keyringID.intValue > 0 else {
                return nil
            }

            // Each entry should have a `value`, an optional `id`, and an optional `key`.
            // If the entry already has a key, then there's nothing to do; Pass the dictionary as is.
            if let _ = entry[Keys.publicizeKeyKey] {
                return entry
            }

            // If the key doesn't exist, this means that the dictionary is still using the old format.
            // Try to add a key with the new format ONLY if the metadata hasn't been synced to the remote.
            let metadataKeyValue: String = {
                guard entry[Keys.publicizeIdKey] == nil,
                      let connections = post.blog.connections as? Set<PublicizeConnection>,
                      let connection = connections.first(where: { $0.keyringConnectionID == keyringID }) else {
                    // Fall back to the old keyring format.
                    return "\(SkipPrefix.keyring.rawValue)\(keyringID)"
                }
                return "\(SkipPrefix.connection.rawValue)\(connection.connectionID)"
            }()

            return entry.merging([Keys.publicizeKeyKey: metadataKeyValue]) { _, newValue in newValue }
        }
    }

}

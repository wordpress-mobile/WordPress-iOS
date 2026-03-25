import WordPressData

extension PostHelper {
    typealias StringDictionary = [String: String]
    typealias Keys = Post.Constants
    typealias SkipPrefix = Post.PublicizeMetadataSkipPrefix

    /// Returns a dictionary format for the `Post`'s `disabledPublicizeConnection` property based on the given metadata.
    ///
    /// This handles both Publicize skip key formats: `_wpas_skip_{keyringID}` and `_wpas_skip_publicize_{connectionID}`.
    /// The dictionary key is always `connectionID`. For keyring format keys, the matching `PublicizeConnection` is
    /// looked up by `keyringConnectionID` to resolve the `connectionID`. If no match is found, the raw ID is used
    /// as a fallback.
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
                        let rawID = Int(key.removingPrefix(SkipPrefix.keyring.rawValue))
                        // Convert keyring ID to connection ID if possible
                        if let rawID,
                           let connections = post.blog.connections,
                           let connection = connections.first(where: { $0.keyringConnectionID.intValue == rawID }) {
                            return connection.connectionID.intValue
                        }
                        // Fall back to raw ID if no matching connection found
                        return rawID

                    case .connection:
                        return Int(key.removingPrefix(SkipPrefix.connection.rawValue))
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

        return disabledConnectionsDictionary.compactMap { (connectionID: NSNumber, entry: StringDictionary) in
            // The previous implementation didn't properly parse `_wpas_skip_publicize_` keys, causing it
            // to use 0 as the dictionary key. Although this will be ignored by the server, let's make sure
            // it's not sent to the remote any longer.
            guard connectionID.intValue > 0 else {
                return nil
            }

            // Each entry should have a `value`, an optional `id`, and an optional `key`.
            // If the entry already has a key, then there's nothing to do; Pass the dictionary as is.
            if let _ = entry[Keys.publicizeKeyKey] {
                return entry
            }

            // For new entries, use the connection format since the key IS the connectionID.
            let metadataKeyValue = "\(SkipPrefix.connection.rawValue)\(connectionID)"

            return entry.merging([Keys.publicizeKeyKey: metadataKeyValue]) { _, newValue in newValue }
        }
    }

}

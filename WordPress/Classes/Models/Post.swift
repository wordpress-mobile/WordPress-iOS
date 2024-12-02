import Foundation
import CoreData

@objc(Post)
class Post: AbstractPost {
    @objc static let typeDefaultIdentifier = "post"

    struct Constants {
        static let publicizeIdKey = "id"
        static let publicizeValueKey = "value"
        static let publicizeKeyKey = "key"
        static let publicizeDisabledValue = "1"
        static let publicizeEnabledValue = "0"
    }

    enum PublicizeMetadataSkipPrefix: String {
        case keyring = "_wpas_skip_"
        case connection = "_wpas_skip_publicize_"

        /// Determines the prefix type from the given key.
        ///
        /// - Parameter key: String.
        /// - Returns: A `PublicizeMetadataSkipPrefix` value, or nil if nothing matched.
        static func prefix(of key: String) -> PublicizeMetadataSkipPrefix? {
            // try to match the `keyring` format first, since it's a substring of the `connection` format.
            guard key.hasPrefix(Self.keyring.rawValue) else {
                return nil
            }
            return key.hasPrefix(Self.connection.rawValue) ? .connection : .keyring
        }
    }

    // MARK: - NSManagedObject

    override class func entityName() -> String {
        return "Post"
    }

    // MARK: - Format

    @objc func postFormatText() -> String? {
        return blog.postFormatText(fromSlug: postFormat)
    }

    @objc func setPostFormatText(_ postFormatText: String) {

        assert(blog.postFormats is [String: String])
        guard let postFormats = blog.postFormats as? [String: String] else {
            DDLogError("Expected blog.postFormats to be \(String(describing: [String: String].self)).")
            return
        }

        var formatKey: String?

        for (key, value) in postFormats {
            if value == postFormatText {
                formatKey = key
                break
            }
        }

        postFormat = formatKey
    }

    // MARK: - Categories

    /// Returns categories as a comma-separated list
    ///
    @objc func categoriesText() -> String {

        guard let allStrings = categories?.map({ return $0.categoryName as String }) else {
            return ""
        }

        let orderedStrings = allStrings.sorted { (categoryName1, categoryName2) -> Bool in
            return categoryName1.localizedCaseInsensitiveCompare(categoryName2) == .orderedAscending
        }

        return orderedStrings.joined(separator: ", ")
    }

    /// Set the categories for a post
    ///
    /// - Parameter categoryNames: a `NSArray` with the names of the categories for this post. If
    ///                     a given category name doesn't exist it's ignored.
    ///
    @objc func setCategoriesFromNames(_ categoryNames: [String]) {

        var newCategories = Set<PostCategory>()

        for categoryName in categoryNames {

            assert(blog.categories is Set<PostCategory>)
            guard let blogCategories = blog.categories as? Set<PostCategory> else {
                DDLogError("Expected blog.categories to be \(String(describing: Set<PostCategory>.self)).")
                return
            }

            let matchingCategories = blogCategories.filter({ return $0.categoryName == categoryName })

            if matchingCategories.count > 0 {
                newCategories = newCategories.union(matchingCategories)
            }
        }

        categories = newCategories
    }

    // MARK: - Sharing

    @objc func canEditPublicizeSettings() -> Bool {
        return !self.hasRemote() || self.status != .publish
    }

    // MARK: - PublicizeConnections

    @objc func publicizeConnectionDisabledForKeyringID(_ keyringID: NSNumber) -> Bool {
        let isKeyringEntryDisabled = disabledPublicizeConnections?[keyringID]?[Constants.publicizeValueKey] == Constants.publicizeDisabledValue

        // try to check in case there's an entry for the PublicizeConnection that's keyed by the connectionID.
        guard let connections = blog.connections as? Set<PublicizeConnection>,
              let connection = connections.first(where: { $0.keyringConnectionID == keyringID }),
              let existingValue = disabledPublicizeConnections?[connection.connectionID]?[Constants.publicizeValueKey] else {
            // fall back to keyringID if there is no such entry with the connectionID.
            return isKeyringEntryDisabled
        }

        let isConnectionEntryDisabled = existingValue == Constants.publicizeDisabledValue
        return isConnectionEntryDisabled || isKeyringEntryDisabled
    }

    @objc func enablePublicizeConnectionWithKeyringID(_ keyringID: NSNumber) {
        // if there's another entry keyed by connectionID references to the same connection,
        // we need to make sure that the values are kept in sync.
        if let connections = blog.connections as? Set<PublicizeConnection>,
           let connection = connections.first(where: { $0.keyringConnectionID == keyringID }),
           let _ = disabledPublicizeConnections?[connection.connectionID] {
            enablePublicizeConnection(keyedBy: connection.connectionID)
        }

        enablePublicizeConnection(keyedBy: keyringID)
    }

    @objc func disablePublicizeConnectionWithKeyringID(_ keyringID: NSNumber) {
        // if there's another entry keyed by connectionID references to the same connection,
        // we need to make sure that the values are kept in sync.
        if let connections = blog.connections as? Set<PublicizeConnection>,
           let connectionID = connections.first(where: { $0.keyringConnectionID == keyringID })?.connectionID,
           let _ = disabledPublicizeConnections?[connectionID] {
            disablePublicizeConnection(keyedBy: connectionID)

            // additionally, if the keyring entry doesn't exist, there's no need create both formats.
            // we can just update the dictionary's key from connectionID to keyringID instead.
            if disabledPublicizeConnections?[keyringID] == nil,
               let updatedEntry = disabledPublicizeConnections?[connectionID] {
                disabledPublicizeConnections?.removeValue(forKey: connectionID)
                disabledPublicizeConnections?[keyringID] = updatedEntry
                return
            }
        }

        disablePublicizeConnection(keyedBy: keyringID)
    }

    /// Marks the Publicize connection with the given id as enabled.
    ///
    /// - Parameter id: The dictionary key for `disabledPublicizeConnections`.
    private func enablePublicizeConnection(keyedBy id: NSNumber) {
        guard var connection = disabledPublicizeConnections?[id] else {
            return
        }

        // if the auto-sharing settings is not yet synced to remote,
        // we can just remove the entry since all connections are enabled by default.
        guard let _ = connection[Constants.publicizeIdKey] else {
            _ = disabledPublicizeConnections?.removeValue(forKey: id)
            return
        }

        connection[Constants.publicizeValueKey] = Constants.publicizeEnabledValue
        disabledPublicizeConnections?[id] = connection
    }

    /// Marks the Publicize connection with the given id as disabled.
    ///
    /// - Parameter id: The dictionary key for `disabledPublicizeConnections`.
    private func disablePublicizeConnection(keyedBy id: NSNumber) {
        if let _ = disabledPublicizeConnections?[id] {
            disabledPublicizeConnections?[id]?[Constants.publicizeValueKey] = Constants.publicizeDisabledValue
            return
        }

        if disabledPublicizeConnections == nil {
            disabledPublicizeConnections = [NSNumber: [String: String]]()
        }

        disabledPublicizeConnections?[id] = [Constants.publicizeValueKey: Constants.publicizeDisabledValue]
    }

    // MARK: - Comments

    @objc func numberOfComments() -> Int {
        return commentCount?.intValue ?? 0
    }

    // MARK: - Likes

    @objc func numberOfLikes() -> Int {
        return likeCount?.intValue ?? 0
    }

    // MARK: - AbstractPost

    override func hasCategories() -> Bool {
        categories?.isEmpty == false
    }

    override func hasTags() -> Bool {
        tags?.trim().isEmpty == false
    }

    override func authorForDisplay() -> String? {
        author ?? blog.account?.displayName
    }

    // MARK: - BasePost

    override func contentPreviewForDisplay() -> String {
        if let excerpt = mt_excerpt, excerpt.count > 0 {
            if let preview = PostPreviewCache.shared.excerpt[excerpt] {
                return preview
            }
            let preview = excerpt.makePlainText()
            PostPreviewCache.shared.excerpt[excerpt] = preview
            return preview
        } else if let content {
            if let preview = PostPreviewCache.shared.content[content] {
                return preview
            }
            let preview = content.summarized()
            PostPreviewCache.shared.content[content] = preview
            return preview
        } else {
            return ""
        }
    }

    override func titleForDisplay() -> String {
        var title = postTitle?.trimmingCharacters(in: CharacterSet.whitespaces) ?? ""
        title = title
            .stringByDecodingXMLCharacters()
            .strippingHTML()

        if title.count == 0 && contentPreviewForDisplay().count == 0 && !hasRemote() {
            title = NSLocalizedString("(no title)", comment: "Lets a user know that a local draft does not have a title.")
        }

        return title
    }
}

private final class PostPreviewCache {
    static let shared = PostPreviewCache()

    let excerpt = Cache<String, String>()
    let content = Cache<String, String>()
}

private final class Cache<Key: Hashable, Value> {
    private let lock = NSLock()
    private var dictionary: [Key: Value] = [:]

    subscript(key: Key) -> Value? {
        get { lock.withLock { dictionary[key] } }
        set { lock.withLock { dictionary[key] = newValue } }
    }
}

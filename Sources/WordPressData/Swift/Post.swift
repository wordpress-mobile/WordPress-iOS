import Foundation
import CoreData
import CocoaLumberjackSwift
import WordPressShared

@objc(Post)
public class Post: AbstractPost {
    @objc static let typeDefaultIdentifier = "post"

    public struct Constants {
        public static let publicizeIdKey = "id"
        static let publicizeValueKey = "value"
        public static let publicizeKeyKey = "key"
        static let publicizeDisabledValue = "1"
        static let publicizeEnabledValue = "0"
    }

    public enum PublicizeMetadataSkipPrefix: String {
        case keyring = "_wpas_skip_"
        case connection = "_wpas_skip_publicize_"

        /// Determines the prefix type from the given key.
        ///
        /// - Parameter key: String.
        /// - Returns: A `PublicizeMetadataSkipPrefix` value, or nil if nothing matched.
        public static func prefix(of key: String) -> PublicizeMetadataSkipPrefix? {
            // try to match the `keyring` format first, since it's a substring of the `connection` format.
            guard key.hasPrefix(Self.keyring.rawValue) else {
                return nil
            }
            return key.hasPrefix(Self.connection.rawValue) ? .connection : .keyring
        }
    }

    // MARK: - NSManagedObject

    public override class func entityName() -> String {
        return "Post"
    }

    // MARK: - Format

    @objc public func postFormatText() -> String? {
        return blog.postFormatText(fromSlug: postFormat)
    }

    @objc public func setPostFormatText(_ postFormatText: String) {

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

    /// Set the categories for a post
    ///
    /// - Parameter categoryNames: a `NSArray` with the names of the categories for this post. If
    ///                     a given category name doesn't exist it's ignored.
    ///
    @objc public func setCategoriesFromNames(_ categoryNames: [String]) {

        var newCategories = Set<PostCategory>()

        for categoryName in categoryNames {

            guard let blogCategories = blog.categories else {
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

    @objc public func canEditPublicizeSettings() -> Bool {
        return !self.hasRemote() || self.status != .publish
    }

    // MARK: - PublicizeConnections

    @objc public func publicizeConnectionDisabled(forConnectionID connectionID: NSNumber) -> Bool {
        disabledPublicizeConnections?[connectionID]?[Constants.publicizeValueKey] == Constants.publicizeDisabledValue
    }

    @objc public func enablePublicizeConnection(forConnectionID connectionID: NSNumber) {
        guard var entry = disabledPublicizeConnections?[connectionID] else {
            return
        }

        // If the entry hasn't been synced to remote yet,
        // remove it since all connections are enabled by default.
        guard let _ = entry[Constants.publicizeIdKey] else {
            _ = disabledPublicizeConnections?.removeValue(forKey: connectionID)
            return
        }

        entry[Constants.publicizeValueKey] = Constants.publicizeEnabledValue
        disabledPublicizeConnections?[connectionID] = entry
    }

    @objc public func disablePublicizeConnection(forConnectionID connectionID: NSNumber) {
        if disabledPublicizeConnections?[connectionID] != nil {
            disabledPublicizeConnections?[connectionID]?[Constants.publicizeValueKey] = Constants.publicizeDisabledValue
            return
        }

        if disabledPublicizeConnections == nil {
            disabledPublicizeConnections = [NSNumber: [String: String]]()
        }

        disabledPublicizeConnections?[connectionID] = [Constants.publicizeValueKey: Constants.publicizeDisabledValue]
    }

    // MARK: - Comments

    @objc public func numberOfComments() -> Int {
        return commentCount?.intValue ?? 0
    }

    // MARK: - Likes

    @objc public func numberOfLikes() -> Int {
        return likeCount?.intValue ?? 0
    }

    // MARK: - AbstractPost

    override public func hasCategories() -> Bool {
        categories?.isEmpty == false
    }

    override public func hasTags() -> Bool {
        tags?.trim().isEmpty == false
    }

    public func authorForDisplay() -> String? {
        author ?? blog.account?.displayName
    }

    public func dateForDisplay() -> Date? {
        return dateCreated
    }

    // MARK: - BasePost

    override public func contentPreviewForDisplay() -> String {
        if let excerpt = mt_excerpt, excerpt.count > 0 {
            if let preview = PostPreviewCache.shared.excerpt[excerpt] {
                return preview
            }
            let preview = excerpt.makePlainText().withCollapsedNewlines()
            PostPreviewCache.shared.excerpt[excerpt] = preview
            return preview
        } else if let content {
            if let preview = PostPreviewCache.shared.content[content] {
                return preview
            }
            let preview = GutenbergExcerptGenerator.firstParagraph(from: content, maxLength: 200).withCollapsedNewlines()
            PostPreviewCache.shared.content[content] = preview
            return preview
        } else {
            return ""
        }
    }

    override public func titleForDisplay() -> String {
        var title = postTitle?.trimmingCharacters(in: CharacterSet.whitespaces) ?? ""
        title = title
            .stringByDecodingXMLCharacters()
            .strippingHTML()

        if title.count == 0 && !hasRemote() && contentPreviewForDisplay().count == 0 {
            title = NSLocalizedString("(no title)", comment: "Lets a user know that a local draft does not have a title.")
        }

        return title
    }
}

private extension String {
    // Normalize newlines by collapsing multiple occurrences of newlines to a single newline
    func withCollapsedNewlines() -> String {
        replacingOccurrences(of: "[\n]{2,}", with: "\n", options: .regularExpression)
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

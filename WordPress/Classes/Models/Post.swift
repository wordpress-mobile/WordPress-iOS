import Foundation
import CoreData
import CocoaLumberjack

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


@objc(Post)
class Post: AbstractPost {
    @objc static let typeDefaultIdentifier = "post"

    struct Constants {
        static let publicizeIdKey = "id"
        static let publicizeValueKey = "value"
        static let publicizeDisabledValue = "1"
        static let publicizeEnabledValue = "0"
    }

    // MARK: - Properties

    fileprivate var storedContentPreviewForDisplay = ""

    // MARK: - NSManagedObject

    override class func entityName() -> String {
        return "Post"
    }

    override func awakeFromFetch() {
        super.awakeFromFetch()
        buildContentPreview()
    }

    override func willSave() {
        super.willSave()

        if isDeleted {
            return
        }

        buildContentPreview()
    }

    // MARK: - Content Preview

    fileprivate func buildContentPreview() {
        if let excerpt = mt_excerpt, excerpt.count > 0 {
            storedContentPreviewForDisplay = NSString.makePlainText(excerpt)
        } else if let content = content {
            storedContentPreviewForDisplay = NSString.summary(fromContent: content)
        }
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
        return disabledPublicizeConnections?[keyringID]?[Constants.publicizeValueKey] == Constants.publicizeDisabledValue
    }

    @objc func enablePublicizeConnectionWithKeyringID(_ keyringID: NSNumber) {
        guard var connection = disabledPublicizeConnections?[keyringID] else {
            return
        }

        guard connection[Constants.publicizeIdKey] != nil else {
            _ = disabledPublicizeConnections?.removeValue(forKey: keyringID)
            return
        }

        connection[Constants.publicizeValueKey] = Constants.publicizeEnabledValue
        disabledPublicizeConnections?[keyringID] = connection
    }

    @objc func disablePublicizeConnectionWithKeyringID(_ keyringID: NSNumber) {
        if let _ = disabledPublicizeConnections?[keyringID] {
            disabledPublicizeConnections![keyringID]![Constants.publicizeValueKey] = Constants.publicizeDisabledValue
        } else {
            if disabledPublicizeConnections == nil {
                disabledPublicizeConnections = [NSNumber: [String: String]]()
            }
            disabledPublicizeConnections?[keyringID] = [Constants.publicizeValueKey: Constants.publicizeDisabledValue]
        }
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

    override func hasSiteSpecificChanges() -> Bool {
        if super.hasSiteSpecificChanges() {
            return true
        }

        assert(original == nil || original is Post)

        if let originalPost = original as? Post {

            if postFormat != originalPost.postFormat {
                return true
            }

            if categories != originalPost.categories {
                return true
            }
        }

        return false
    }

    override func hasCategories() -> Bool {
        return (categories?.count > 0)
    }

    override func hasTags() -> Bool {
        return (tags?.trim().count > 0)
    }

    // MARK: - BasePost

    override func contentPreviewForDisplay() -> String {
        if storedContentPreviewForDisplay.count == 0 {
            buildContentPreview()
        }

        return storedContentPreviewForDisplay
    }

    override func hasLocalChanges() -> Bool {
        if super.hasLocalChanges() {
            return true
        }

        assert(original == nil || original is Post)

        if let originalPost = original as? Post {

            if tags ?? "" != originalPost.tags ?? "" {
                return true
            }

            if let coord1 = geolocation?.coordinate,
                let coord2 = originalPost.geolocation?.coordinate, coord1.latitude != coord2.latitude || coord1.longitude != coord2.longitude {

                return true
            }

            if (geolocation == nil && originalPost.geolocation != nil) || (geolocation != nil && originalPost.geolocation == nil) {
                return true
            }

            if publicizeMessage ?? "" != originalPost.publicizeMessage ?? "" {
                return true
            }

            if !NSDictionary(dictionary: disabledPublicizeConnections ?? [:])
                             .isEqual(to: originalPost.disabledPublicizeConnections ?? [:]) {
                return true
            }

            if isStickyPost != originalPost.isStickyPost {
                return true
            }
        }

        return false
    }

    override func statusForDisplay() -> String? {
        var statusString: String?

        if status == .trash || status == .scheduled {
            statusString = ""
        } else if status != .publish && status != .draft {
            statusString = statusTitle
        }

        if isRevision() {
            let localOnly = NSLocalizedString("Local changes", comment: "A status label for a post that only exists on the user's iOS device, and has not yet been published to their blog.")

            if let tempStatusString = statusString, !tempStatusString.isEmpty {
                statusString = String(format: "%@, %@", tempStatusString, localOnly)
            } else {
                statusString = localOnly
            }
        }

        return statusString
    }

    override func titleForDisplay() -> String {
        var title = postTitle?.trimmingCharacters(in: CharacterSet.whitespaces) ?? ""
        title = title.stringByDecodingXMLCharacters()

        if title.count == 0 && contentPreviewForDisplay().count == 0 && !hasRemote() {
            title = NSLocalizedString("(no title)", comment: "Lets a user know that a local draft does not have a title.")
        }

        return title
    }

    override func additionalContentHashes() -> [Data] {
        // Since the relationship between the categories and a Post is a `Set` and not a `OrderedSet`, we
        // need to sort it manually here, so it won't magically change between runs.
        let stringifiedCategories = categories?.compactMap { $0.categoryName }.sorted().reduce("") { acc, obj in
            return acc + obj
        } ?? ""

        return [hash(for: publicID ?? ""),
                hash(for: tags ?? ""),
                hash(for: postFormat ?? ""),
                hash(for: stringifiedCategories),
                hash(for: geolocation?.latitude ?? 0),
                hash(for: geolocation?.longitude ?? 0),
                hash(for: isStickyPost ? 1 : 0)]
    }
}

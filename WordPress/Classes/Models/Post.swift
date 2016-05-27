import Foundation
import CoreData

@objc(Post)
class Post: AbstractPost {

    static let entityName = "Post"
    static let typeDefaultIdentifier = "post"

    // MARK: - Properties

    private var storedContentPreviewForDisplay = ""

    // MARK: - NSManagedObject

    override func awakeFromFetch() {
        super.awakeFromFetch()
        buildContentPreview()
    }

    override func willSave() {
        super.willSave()

        if deleted {
            return
        }

        buildContentPreview()
    }

    // MARK: - Content Preview

    private func buildContentPreview() {
        if let excerpt = mt_excerpt where excerpt.characters.count > 0 {
            storedContentPreviewForDisplay = String.makePlainText(excerpt)
        } else if let content = content {
            storedContentPreviewForDisplay = BasePost.summaryFromContent(content)
        }
    }

    // MARK: - Format

    func postFormatText() -> String? {
        guard let postFormat = postFormat else {
            return nil
        }

        return blog.postFormatTextFromSlug(postFormat)
    }

    func setPostFormatText(postFormatText: String) {

        assert(blog.postFormats is [String:String])
        guard let postFormats = blog.postFormats as? [String:String] else {
            DDLogSwift.logError("Expected blog.postFormats to be \(String([String:String])).")
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
    func categoriesText() -> String {

        guard let allStrings = categories?.map({ return $0.categoryName as String }) else {
            return ""
        }

        let orderedStrings = allStrings.sort { (categoryName1, categoryName2) -> Bool in
            return categoryName1.localizedCaseInsensitiveCompare(categoryName2) == .OrderedAscending
        }

        return orderedStrings.joinWithSeparator(", ")
    }


    /// Set the categories for a post
    ///
    /// - Parameter categoryNames: a `NSArray` with the names of the categories for this post. If
    ///                     a given category name doesn't exist it's ignored.
    ///
    func setCategoriesFromNames(categoryNames: [String]) {

        var newCategories = Set<PostCategory>()

        for categoryName in categoryNames {

            assert(blog.categories is Set<PostCategory>)
            guard let blogCategories = blog.categories as? Set<PostCategory> else {
                DDLogSwift.logError("Expected blog.categories to be \(String(Set<PostCategory>)).")
                return
            }

            let matchingCategories = blogCategories.filter({ return $0.categoryName == categoryName })

            if matchingCategories.count > 0 {
                newCategories = newCategories.union(matchingCategories)
            }
        }

        categories = newCategories
    }

    // MARK: - Comments

    func numberOfComments() -> Int {
        return commentCount?.integerValue ?? 0
    }

    // MARK: - Likes

    func numberOfLikes() -> Int {
        return likeCount?.integerValue ?? 0
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
        return (categories?.count > 0) ?? false
    }

    override func hasTags() -> Bool {
        return (tags?.trim().characters.count > 0) ?? false
    }

    // MARK: - BasePost

    override func contentPreviewForDisplay() -> String {
        if storedContentPreviewForDisplay.characters.count == 0 {
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

            if tags?.characters.count != originalPost.tags?.characters.count && tags != originalPost.tags {
                return true
            }

            if let coord1 = geolocation?.coordinate,
                let coord2 = originalPost.geolocation?.coordinate
                where coord1.latitude != coord2.latitude || coord1.longitude != coord2.longitude {

                return true
            }
        }

        return false
    }

    override func statusForDisplay() -> String? {
        var statusString: String?

        if status != PostStatusPublish && status != PostStatusDraft {
            statusString = statusTitle
        }

        if isRevision() {
            let localOnly = NSLocalizedString("Local", comment: "A status label for a post that only exists on the user's iOS device, and has not yet been published to their blog.")

            if let tempStatusString = statusString {
                statusString = String(format: "%@, %@", tempStatusString, localOnly)
            } else {
                statusString = localOnly
            }
        }

        return statusString
    }

    override func titleForDisplay() -> String {
        var title = postTitle?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) ?? ""
        title = title.stringByDecodingXMLCharacters()

        if title.characters.count == 0 && contentPreviewForDisplay().characters.count == 0 && !hasRemote() {
            title = NSLocalizedString("(no title)", comment: "Lets a user know that a local draft does not have a title.")
        }

        return title
    }

    override func featuredImageURLForDisplay() -> NSURL? {

        guard let path = pathForDisplayImage else {
            return nil
        }

        return NSURL(string: path)
    }
}

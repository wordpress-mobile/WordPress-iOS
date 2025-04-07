import Foundation
import WordPressShared

public extension PostHelper {
    @objc static let foreignIDKey = "wp_jp_foreign_id"

    static func mapDictionaryToMetadataItems(_ dictionary: [String: Any]) -> RemotePostMetadataItem? {
        let id = dictionary["id"]
        return RemotePostMetadataItem(
            id: (id as? String) ?? (id as? NSNumber)?.stringValue,
            key: dictionary["key"] as? String,
            value: dictionary["value"] as? String
        )
    }

    @objc(createOrUpdateCategoryForRemoteCategory:blog:context:)
    class func createOrUpdateCategory(for remoteCategory: RemotePostCategory, in blog: Blog, in context: NSManagedObjectContext) -> PostCategory? {
        guard let categoryID = remoteCategory.categoryID else {
            wpAssertionFailure("remote category missing categoryID")
            return nil
        }
        if let category = try? PostCategory.lookup(withBlogID: blog.objectID, categoryID: categoryID, in: context) {
            return category
        }
        let category = PostCategory(context: context)
        // - warning: these PostCategory fields are explicitly unwrapped optionals!
        category.blog = blog
        category.categoryID = categoryID
        category.categoryName = remoteCategory.name ?? ""
        category.parentID = remoteCategory.parentID ?? 0 // `0` means "no parent"
        return category
    }
}

import Foundation
import WordPressShared
import WordPressKit

extension PostHelper {
    @objc public static let foreignIDKey = "wp_jp_foreign_id"

    @objc public static func makeRawMetadata(from post: RemotePost) -> Data? {
        guard let metadata = post.metadata else {
            return nil
        }
        guard JSONSerialization.isValidJSONObject(metadata) else {
            wpAssertionFailure("metadata is not a valid JSON object")
            return nil
        }
        do {
            return try JSONSerialization.data(withJSONObject: metadata)
        } catch {
            wpAssertionFailure("failed to convert metadata to JSON", userInfo: ["error": "\(error)"])
            return nil
        }
    }

    public static func mapDictionaryToMetadataItems(_ dictionary: [String: Any]) -> RemotePostMetadataItem? {
        let id = dictionary["id"]
        return RemotePostMetadataItem(
            id: (id as? String) ?? (id as? NSNumber)?.stringValue,
            key: dictionary["key"] as? String,
            value: dictionary["value"] as? String
        )
    }

    @objc(createOrUpdateCategoryForRemoteCategory:blog:context:)
    public class func createOrUpdateCategory(for remoteCategory: RemotePostCategory, in blog: Blog, in context: NSManagedObjectContext) -> PostCategory? {
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

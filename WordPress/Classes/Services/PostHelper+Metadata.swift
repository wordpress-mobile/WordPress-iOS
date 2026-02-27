import Foundation
import WordPressData
import WordPressKit
import WordPressShared

extension PostHelper {
    @objc static let foreignIDKey = PostMetadataContainer.Key.foreignID.rawValue

    @objc static func getForeignID(for post: RemotePost) -> UUID? {
        guard let metadata = post.metadata as? [[String: Any]] else {
            return nil
        }
        let container = PostMetadataContainer(metadata: metadata)
        guard let value = container.getString(for: .foreignID) else {
            return nil
        }
        return UUID(uuidString: value)
    }

    @objc static func makeRawMetadata(from post: RemotePost) -> Data? {
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

import Foundation
import CoreData
import WordPressKit

@objc(PostUploadOperation)
public class PostUploadOperation: UploadOperation {
    /// Remote post ID for this upload op.
    ///
    @NSManaged public var remotePostID: Int64

    /// Post subject for this upload op
    ///
    @NSManaged public var postTitle: String?

    /// Post content for this upload op
    ///
    @NSManaged public var postContent: String?

    /// Post tags for this upload op
    ///
    @NSManaged public var postTags: String?

    /// Post categories for this upload op
    ///
    @NSManaged public var postCategories: String?

    /// Post type for this upload op
    ///
    @NSManaged public var postType: String?

    /// Post status for this upload op — e.g. "Draft" or "Publish" (Not used if `isMedia` is True)
    ///
    @NSManaged public var postStatus: String?
}

// MARK: - Computed Properties

extension PostUploadOperation {
    /// Returns a RemotePost object based on this PostUploadOperation
    ///
    var remotePost: RemotePost {
        let remotePost = RemotePost()
        remotePost.postID = NSNumber(value: remotePostID)
        remotePost.content = postContent
        remotePost.title = postTitle
        remotePost.status = postStatus
        remotePost.siteID = NSNumber(value: siteID)
        remotePost.tags = postTags?.arrayOfTags() ?? []
        remotePost.categories = RemotePostCategory.remotePostCategoriesFromString(postCategories) ?? []
        remotePost.type = postType

        return remotePost
    }
}

// MARK: - Update Helpers

extension PostUploadOperation {
    /// Updates the local fields with the new values stored in a given RemotePost
    ///
    func updateWithPost(remote: RemotePost) {

        if let postId = remote.postID?.int64Value {
            remotePostID = postId
        }
        if let siteId = remote.siteID?.int64Value {
            siteID = siteId
        }
        postTitle = remote.title
        postContent = remote.content
        postStatus = remote.status

        if let tags = remote.tags as? [String] {
            postTags = tags.joined(separator: ", ")
        }

        if let categories = remote.categories as? [RemotePostCategory], !categories.isEmpty {
            postCategories = categories.map({ $0.categoryID.stringValue }).joined(separator: ", ")
        }

        postType = remote.type
    }
}

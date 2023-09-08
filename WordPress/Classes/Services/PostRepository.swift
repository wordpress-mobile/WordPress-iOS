import Foundation

final class PostRepository {

    enum Error: Swift.Error {
        case postNotFound
        case remoteAPIUnavailable
    }

    private let coreDataStack: CoreDataStackSwift
    private let remoteFactory: PostServiceRemoteFactory

    init(coreDataStack: CoreDataStackSwift, remoteFactory: PostServiceRemoteFactory = PostServiceRemoteFactory()) {
        self.coreDataStack = coreDataStack
        self.remoteFactory = remoteFactory
    }

    /// Sync a specific post from the API
    ///
    /// - Parameters:
    ///   - postID: The ID of the post to sync
    ///   - blogID: The blog that has the post.
    /// - Returns: The stored post object id.
    func getPost(withID postID: NSNumber, from blogID: TaggedManagedObjectID<Blog>) async throws -> TaggedManagedObjectID<AbstractPost> {
        let remote = try await coreDataStack.performQuery { [remoteFactory] context in
            let blog = try context.existingObject(with: blogID)
            return remoteFactory.forBlog(blog)
        }

        guard let remote else {
            throw PostRepository.Error.remoteAPIUnavailable
        }

        let remotePost: RemotePost? = try await withCheckedThrowingContinuation { continuation in
            remote.getPostWithID(
                postID,
                success: { continuation.resume(returning: $0) },
                failure: { continuation.resume(throwing: $0!) }
            )
        }

        guard let remotePost else {
            throw PostRepository.Error.postNotFound
        }

        return try await coreDataStack.performAndSave { context in
            let blog = try context.existingObject(with: blogID)

            let post: AbstractPost
            if let existingPost = blog.lookupPost(withID: postID, in: context) {
                post = existingPost
            } else {
                if remotePost.type == PostServiceType.page.rawValue {
                    post = blog.createPage()
                } else {
                    post = blog.createPost()
                }
            }

            PostHelper.update(post, with: remotePost, in: context)

            return .init(post)
        }
    }

    /// Permanently delete the given post from local database and the post's WrodPress site.
    ///
    /// - Parameter postID: Object ID of the post
    func delete<P: AbstractPost>(_ postID: TaggedManagedObjectID<P>) async throws {
        // Delete the original post instead if presents
        let original: TaggedManagedObjectID<AbstractPost>? = try await coreDataStack.performQuery { context in
            let post = try context.existingObject(with: postID)
            if let original = post.original {
                return TaggedManagedObjectID(original)
            }
            return nil
        }
        if let original {
            DDLogInfo("Delete the original post object instead")
            try await delete(original)
            return
        }

        // First delete the post from local database.
        let (remote, remotePost) = try await coreDataStack.performAndSave { [remoteFactory] context in
            let post = try context.existingObject(with: postID)
            context.deleteObject(post)
            return (remoteFactory.forBlog(post.blog), PostHelper.remotePost(with: post))
        }

        // Then delete the post from the server
        guard let remote, let remotePostID = remotePost.postID, remotePostID.int64Value > 0 else {
            DDLogInfo("The post does not exist on the server")
            return
        }

        try await withCheckedThrowingContinuation { continuation in
            remote.delete(
                remotePost,
                success: { continuation.resume(returning: ()) },
                failure: { continuation.resume(throwing: $0!) }
            )
        }
    }

}

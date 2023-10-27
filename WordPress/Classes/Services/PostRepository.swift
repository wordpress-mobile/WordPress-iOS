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

    /// Permanently delete the given post from local database and the post's WordPress site.
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

        let status = try await coreDataStack.performQuery { try $0.existingObject(with: postID).status }
        assert(status == .trash, "This function can only be used to delete trashed posts/pages.")

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

    /// Move the given post to the trash bin. The post will not be deleted from local database, unless it's delete on its WordPress site.
    ///
    /// - Parameter postID: Object ID of the post
    func trash<P: AbstractPost>(_ postID: TaggedManagedObjectID<P>) async throws {
        // Trash the original post instead if presents
        let original: TaggedManagedObjectID<AbstractPost>? = try await coreDataStack.performQuery { context in
            let post = try context.existingObject(with: postID)
            if let original = post.original {
                return TaggedManagedObjectID(original)
            }
            return nil
        }
        if let original {
            DDLogInfo("Trash the original post object instead")
            try await trash(original)
            return
        }

        // If the post is already in Trash, delete it.
        let shouldDelete = try await coreDataStack.performQuery { context in
            (try context.existingObject(with: postID)).status == .trash
        }
        if shouldDelete {
            DDLogInfo("The post is already trashed, delete it instead")
            try await delete(postID)
            return
        }

        // Update local database and check if we need to call WordPress API.
        let shouldCallRemote = try await coreDataStack.performAndSave { context in
            let post = try context.existingObject(with: postID)
            if post.isRevision() || (post.postID?.int64Value ?? 0) <= 0 {
                post.status = .trash
                return false
            }

            // The `status` will be updated when the WordPress API call is successful.
            return true
        }
        guard shouldCallRemote else { return }

        // Make the changes on the server
        let (remote, remotePost) = try await coreDataStack.performQuery { [remoteFactory] context in
            let post = try context.existingObject(with: postID)
            return (remoteFactory.forBlog(post.blog), PostHelper.remotePost(with: post))
        }
        guard let remote else { return }

        let updatedRemotePost = try await withCheckedThrowingContinuation { continuation in
            remote.trashPost(
                remotePost,
                success: { continuation.resume(returning: $0) },
                failure: { continuation.resume(throwing: $0!) }
            )
        }

        try? await coreDataStack.performAndSave { context in
            let post = try context.existingObject(with: postID)
            if let updatedRemotePost, updatedRemotePost.status != PostStatusDeleted {
                PostHelper.update(post, with: updatedRemotePost, in: context)
                post.latest().statusAfterSync = post.statusAfterSync
                post.latest().status = post.status
            } else {
                context.deleteObject(post)
            }
        }
    }

    /// Move the given post out of the trash bin.
    ///
    /// - Parameters:
    ///   - postID: Object ID of the given post
    ///   - status: The post's original status before it's moved to the trash bin.
    func restore<P: AbstractPost>(_ postID: TaggedManagedObjectID<P>, to status: BasePost.Status) async throws {
        // Restore the original post instead if presents
        let original: TaggedManagedObjectID<AbstractPost>? = try await coreDataStack.performQuery { context in
            let post = try context.existingObject(with: postID)
            if let original = post.original {
                return TaggedManagedObjectID(original)
            }
            return nil
        }
        if let original {
            DDLogInfo("Trash the original post object instead")
            try await restore(original, to: status)
            return
        }

        // Update local database
        let result: (PostServiceRemote, RemotePost)? = try await coreDataStack.performAndSave { [remoteFactory] context in
            let post = try context.existingObject(with: postID)
            post.status = status

            if let remote = remoteFactory.forBlog(post.blog), !post.isRevision() && (post.postID?.int64Value ?? 0) > 0 {
                return (remote, PostHelper.remotePost(with: post))
            }
            return nil
        }

        // Call WordPress API if needed
        guard let (remote, remotePost) = result else { return }

        let updatedRemotePost: RemotePost
        do {
            updatedRemotePost = try await withCheckedThrowingContinuation { continuation in
                remote.restore(remotePost, success: { continuation.resume(returning: $0!) }, failure: { continuation.resume(throwing: $0!)} )
            }
        } catch {
            DDLogError("Failed to restore post: \(error)")

            // Put the post back in the trash bin.
            try? await coreDataStack.performAndSave { context in
                let post = try context.existingObject(with: postID)
                post.status = .trash
            }
            throw error
        }

        try? await coreDataStack.performAndSave { context in
            let post = try context.existingObject(with: postID)
            PostHelper.update(post, with: updatedRemotePost, in: context)
        }
    }

}

// MARK: - Posts/Pages List

private final class PostRepositoryPostsSerivceRemoteOptions: NSObject, PostServiceRemoteOptions {
    struct Options {
        var statuses: [String]?
        var number: Int = 100
        var offset: Int = 0
        var order: PostServiceResultsOrder = .descending
        var orderBy: PostServiceResultsOrdering = .byDate
        var authorID: NSNumber?
        var search: String?
        var meta: String? = "autosave"
        var tag: String?
    }

    var options: Options

    init(options: Options) {
        self.options = options
    }

    func statuses() -> [String]? {
        options.statuses
    }

    func number() -> NSNumber {
        NSNumber(value: options.number)
    }

    func offset() -> NSNumber {
        NSNumber(value: options.offset)
    }

    func order() -> PostServiceResultsOrder {
        options.order
    }

    func orderBy() -> PostServiceResultsOrdering {
        options.orderBy
    }

    func authorID() -> NSNumber? {
        options.authorID
    }

    func search() -> String? {
        options.search
    }

    func meta() -> String? {
        options.meta
    }

    func tag() -> String! {
        options.tag
    }
}

private extension PostServiceRemote {

    func getPosts(ofType type: String, options: PostRepositoryPostsSerivceRemoteOptions) async throws -> [RemotePost] {
        try await withCheckedThrowingContinuation { continuation in
            self.getPostsOfType(type, options: self.dictionary(with: options), success: {
                continuation.resume(returning: $0 ?? [])
            }, failure: {
                continuation.resume(throwing: $0!)
            })
        }
    }
}

extension PostRepository {

    /// Fetch posts or pages from the given site page by page. All fetched posts are saved to the local database.
    ///
    /// - Parameters:
    ///   - type: `Post.self` and `Page.self` are the only acceptable types.
    ///   - statuses: Filter posts or pages with given status.
    ///   - authorUserID: Filter posts or pages that are authored by given user.
    ///   - offset: The position of the paginated request. Pass 0 for the first page and count of already fetched results for following pages.
    ///   - number: Number of posts or pages should be fetched.
    ///   - blogID: The blog from which to fetch posts or pages
    /// - Returns: Object identifiers of the fetched posts.
    /// - SeeAlso: https://developer.wordpress.com/docs/api/1.1/get/sites/%24site/posts/
    func paginate<P: AbstractPost>(
        type: P.Type = P.self,
        statuses: [BasePost.Status],
        authorUserID: NSNumber? = nil,
        offset: Int,
        number: Int,
        in blogID: TaggedManagedObjectID<Blog>
    ) async throws -> [TaggedManagedObjectID<P>] {
        try await fetch(
            type: type,
            statuses: statuses,
            authorUserID: authorUserID,
            range: offset..<(offset + max(number, 0)),
            orderBy: .byDate,
            descending: true,
            // Only delete other local posts if the current call is the first pagination request.
            deleteOtherLocalPosts: offset == 0,
            in: blogID
        )
    }

    /// Search posts or pages in the given site. All fetched posts are saved to the local database.
    ///
    /// - Parameters:
    ///   - type: `Post.self` and `Page.self` are the only acceptable types.
    ///   - input: The text input from user. Or `nil` for searching all posts or pages.
    ///   - statuses: Filter posts or pages with given status.
    ///   - authorUserID: Filter posts or pages that are authored by given user.
    ///   - limit: Number of posts or pages should be fetched.
    ///   - orderBy: The property by which to sort posts or pages.
    ///   - descending: Whether to sort the results in descending order.
    ///   - blogID: The blog from which to search posts or pages
    /// - Returns: Object identifiers of the search result.
    /// - SeeAlso: https://developer.wordpress.com/docs/api/1.1/get/sites/%24site/posts/
    func search<P: AbstractPost>(
        type: P.Type = P.self,
        input: String?,
        statuses: [BasePost.Status],
        authorUserID: NSNumber? = nil,
        limit: Int,
        orderBy: PostServiceResultsOrdering,
        descending: Bool,
        in blogID: TaggedManagedObjectID<Blog>
    ) async throws -> [TaggedManagedObjectID<P>] {
        try await fetch(
            type: type,
            searchInput: input,
            statuses: statuses,
            authorUserID: authorUserID,
            range: 0..<max(limit, 0),
            orderBy: orderBy,
            descending: descending,
            deleteOtherLocalPosts: false,
            in: blogID
        )
    }

    private func fetch<P: AbstractPost>(
        type: P.Type,
        searchInput: String? = nil,
        statuses: [BasePost.Status]?,
        authorUserID: NSNumber?,
        range: Range<Int>,
        orderBy: PostServiceResultsOrdering = .byDate,
        descending: Bool = true,
        deleteOtherLocalPosts: Bool,
        in blogID: TaggedManagedObjectID<Blog>
    ) async throws -> [TaggedManagedObjectID<P>] {
        assert(type == Post.self || type == Page.self, "Only support fetching Post or Page")
        assert(range.lowerBound >= 0)

        let postType: String
        if type == Post.self {
            postType = "post"
        } else if type == Page.self {
            postType = "page"
        } else {
            // There is an assertion above to ensure the app doesn't fall into this case.
            return []
        }

        let remote = try await coreDataStack.performQuery { [remoteFactory] context in
            let blog = try context.existingObject(with: blogID)
            return remoteFactory.forBlog(blog)
        }
        guard let remote else {
            throw PostRepository.Error.remoteAPIUnavailable
        }

        let options = PostRepositoryPostsSerivceRemoteOptions(options: .init(
            statuses: statuses?.strings,
            number: range.count,
            offset: range.lowerBound,
            order: descending ? .descending : .ascending,
            orderBy: orderBy,
            authorID: authorUserID,
            search: searchInput
        ))
        let remotePosts = try await remote.getPosts(ofType: postType, options: options)

        let updatedPosts = try await coreDataStack.performAndSave { context in
            let updatedPosts = PostHelper.merge(
                remotePosts,
                ofType: postType,
                withStatuses: statuses?.strings,
                byAuthor: authorUserID,
                for: try context.existingObject(with: blogID),
                purgeExisting: deleteOtherLocalPosts,
                in: context
            )
            return updatedPosts.map {
                guard let post = $0 as? P else {
                    fatalError("Expecting a \(postType) as \(type), but got \($0)")
                }
                return TaggedManagedObjectID(post)
            }
        }

        return updatedPosts
    }

}

import Foundation
import WordPressData
import WordPressKit
import WordPressShared

final class PostRepository {

    enum Error: Swift.Error, LocalizedError {
        case remoteAPIUnavailable
        case hasUnsyncedChanges
        case missingPostID // Should never happen

        var errorDescription: String? {
            switch self {
            case .remoteAPIUnavailable: return Strings.genericErrorMessage
            case .hasUnsyncedChanges: return Strings.errorUnsyncedChangesMessage
            case .missingPostID: return Strings.genericErrorMessage
            }
        }
    }

    private let coreDataStack: CoreDataStackSwift
    private let remoteFactory: PostServiceRemoteFactory

    init(coreDataStack: CoreDataStackSwift = ContextManager.shared,
         remoteFactory: PostServiceRemoteFactory = PostServiceRemoteFactory()) {
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
        let remote = try await getRemoteService(forblogID: blogID)
        let remotePost = try await remote.post(withID: postID.intValue)
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

    enum PostSaveError: Swift.Error, LocalizedError {
        /// A conflict between the client and the server versions is detected.
        /// The app needs to consolidate the changes and retry.
        ///
        /// - note: This error is only thrown in case there is an actual conflict
        /// in data, typically `content`. In most cases, the `save()` method
        /// will be able to merge the changes automatically.
        case conflict(latest: RemotePost)

        /// Post was deleted on the remote and can not be updated.
        case deleted(title: String?)

        var errorDescription: String? {
            switch self {
            case .conflict:
                return NSLocalizedString("postSaveErrorMessage.conflict", value: "The content was modified on another device", comment: "Error message: content was modified on another device")
            case .deleted(let title):
                let format = NSLocalizedString("postSaveErrorMessage.deleted", value: "\"%@\" was permanently deleted and can no longer be updated", comment: "Error message: item permanently deleted")
                let untitled = NSLocalizedString("postSaveErrorMessage.postUntitled", value: "Untitled", comment: "A default value for an post without a title")
                return String(format: format, title ?? untitled)
            }
        }
    }

    /// Saves the changes made to the given post on the server or creates a new
    /// post if it doesn't exist on the remote.
    ///
    /// There are three ways to modify a post:
    ///
    /// - Create a revision using ``AbstractPost/createRevision()`` and edit it.
    /// The revisions can be saved to a database and uploaded later.
    /// - Pass the changes directly using ``RemotePostUpdateParameters``. These
    /// changes are saved to the database only _after_ the upload.
    /// - A combination of both
    ///
    /// For both revisions and the changes passed directly, the app sends only
    /// the delta, making sure that it doesn't overwrite any of the other fields.
    ///
    /// - important: Make sure the media used in the post is uploaded before
    /// calling this method.
    ///
    /// - throws: This method throws a ``PostSaveError`` error for scenarios that
    /// require special handling or an error from the underlying system.
    ///
    /// - parameters:
    ///   - post: The post to be synced (original revision) .
    ///   - changes: A set of (optional) changes to be applied on top of the post
    ///   or its latest revision.
    ///   - overwrite: Set to `true` to overwrite the values on the server and
    ///   ignore the ``PostSaveError/conflict(latest:)`` error.
    @MainActor
    func save(_ post: AbstractPost, changes: RemotePostUpdateParameters? = nil, overwrite: Bool = false) async throws {
        try await _sync(post, revision: post.latest(), changes: changes, overwrite: overwrite)
    }

    /// Syncs revisions that have unsaved changes (see `isSyncNeeded`).
    ///
    /// - note: This method is designed to be used with drafts.
    @MainActor
    func sync(_ post: AbstractPost, revision: AbstractPost? = nil) async throws {
        wpAssert(post.original == nil, "Must be called on an original post")
        guard let revision = revision ?? post.getLatestRevisionNeedingSync() else {
            return wpAssertionFailure("Requires a revision")
        }
        try await _sync(post, revision: revision)
    }

    /// - parameter revision: The revision to upload (doesn't have to
    /// be the latest revision).
    @MainActor
    private func _sync(
        _ post: AbstractPost,
        revision: AbstractPost,
        changes: RemotePostUpdateParameters? = nil,
        overwrite: Bool = false
    ) async throws {
        wpAssert(post.isOriginal())
        let post = post.original() // Defensive code
        let context = coreDataStack.mainContext

        let remotePost: RemotePost
        var isCreated = false
        if let postID = post.postID?.intValue, postID > 0 {
            let changes = RemotePostUpdateParameters.changes(from: post, to: revision, with: changes)
            guard !changes.isEmpty else {
                post.deleteSyncedRevisions(until: revision) // Nothing to sync
                ContextManager.shared.saveContextAndWait(context)
                return
            }
            remotePost = try await _patch(post, postID: postID, changes: changes, overwrite: overwrite)
        } else {
            isCreated = true
            remotePost = try await _create(revision, changes: changes)
        }

        if revision.revision == nil {
            PostHelper.update(post, with: remotePost, in: context, overwrite: true)
        } else {
            apply(remotePost, to: post, revision: revision)
        }
        post.deleteSyncedRevisions(until: revision)

        if isCreated {
            PostService(managedObjectContext: context)
                .updateMediaFor(post: post, success: {}, failure: { _ in })
        }
        ContextManager.shared.saveContextAndWait(context)

        WPAnalytics.track(isCreated ? .postRepositoryPostCreated : .postRepositoryPostUpdated, properties: post.analyticsUserInfo)
    }

    // The app currently computes changes between revision to track what
    // needs to be uploaded on the server to reduce the risk of overwriting changes.
    //
    // The problem arises if you have more than one saved revision. Let's
    // say you start with revision R1, then save save R2, and, while R2 is
    // still syncing, save another revision – R3:
    //
    // R1 → R2 → R3
    //
    // This scenario is problematic for the conflict detection mechanism.
    // When uploading `post.content`, the server might ever so slightly
    // change it – e.g. remove redundant spaces in tag attributes. So,
    // unless the app saves the new `dateModified` and/or saves the
    // changed `content`, it *will* detect a false-positive data conflict.
    //
    // Another caveat is that R1 could be a new draft, and then the app
    // needs to save the `postID`.
    private func apply(_ remotePost: RemotePost, to original: AbstractPost, revision: AbstractPost) {
        // Keep the changes consistent across revisions.
        original.clone(from: revision)

        // But update the parts that might end up leading to data conflicts.
        original.postID = remotePost.postID
        original.content = remotePost.content
        original.dateModified = remotePost.dateModified
    }

    /// Patches the post.
    ///
    /// - note: This method can be used for quick edits for published posts where
    /// revisions are used only for content.
    @MainActor
    func update(_ post: AbstractPost, changes: RemotePostUpdateParameters) async throws {
        wpAssert(post.isOriginal())

        guard post.revision == nil else {
            throw PostRepository.Error.hasUnsyncedChanges
        }
        guard let postID = post.postID?.intValue, postID > 0 else {
            wpAssertionFailure("Trying to patch a non-existent post")
            throw PostRepository.Error.missingPostID
        }
        let uploadedPost = try await _patch(post, postID: postID, changes: changes, overwrite: true)

        let context = coreDataStack.mainContext
        PostHelper.update(post, with: uploadedPost, in: context, overwrite: true)
        ContextManager.shared.saveContextAndWait(context)
    }

    @MainActor
    private func _create(_ post: AbstractPost, changes: RemotePostUpdateParameters?) async throws -> RemotePost {
        let service = try getRemoteService(for: post.blog)
        var parameters = RemotePostCreateParameters(post: post)
        if let changes {
            parameters.apply(changes)
        }
        return try await service.createPost(with: parameters)
    }

    @MainActor
    private func _patch(_ post: AbstractPost, postID: Int, changes: RemotePostUpdateParameters, overwrite: Bool) async throws -> RemotePost {
        WPAnalytics.track(.postRepositoryPatchStarted)
        let service = try getRemoteService(for: post.blog)
        let original = post.original()
        var changes = changes

        // Make sure the app never overwrites the content without the user approval.
        if !overwrite, let date = original.dateModified, changes.content != nil {
            changes.ifNotModifiedSince = date
        }

        do {
            return try await service.patchPost(withID: postID, parameters: changes)
        } catch {
            guard let error = error as? PostServiceRemoteError else {
                throw error
            }
            switch error {
            case .conflict:
                // Fetch the latest post to consolidate the changes
                let remotePost = try await service.post(withID: postID)
                // Check for false positives
                if changes.content != nil && remotePost.content != changes.content && remotePost.content != original.content {
                    WPAnalytics.track(.postRepositoryConflictEncountered, properties: ["false_positive": false])
                    // The conflict in content can be resolved only manually
                    throw PostSaveError.conflict(latest: remotePost)
                }
                WPAnalytics.track(.postRepositoryConflictEncountered, properties: ["false_positive": true])

                // There is no conflict, so go ahead and overwrite the changes
                changes.ifNotModifiedSince = nil
                return try await service.patchPost(withID: postID, parameters: changes)
            case .notFound:
                // Delete the post from the local database
                throw PostRepository.PostSaveError.deleted(title: original.titleForDisplay())
            }
        }
    }

    /// Resolves the conflict by overwriting the changes made locally with the
    /// selected remote revision.
    @MainActor
    func resolveConflict(for post: AbstractPost, pickingRemoteRevision revision: RemotePost) throws {
        let context = coreDataStack.mainContext
        post.deleteRevision()
        PostHelper.update(post, with: revision, in: context)
        ContextManager.shared.saveContextAndWait(context)
    }

    /// Trashes the given post.
    ///
    /// - warning: This method delets all local revision of the post.
    @MainActor
    func trash(_ post: AbstractPost) async throws {
        wpAssert(post.isOriginal())

        let context = coreDataStack.mainContext

        guard let postID = post.postID?.intValue, postID > 0 else {
            context.deleteObject(post) // Delete all the local data
            ContextManager.shared.saveContextAndWait(context)
            return
        }

        post.deleteAllRevisions()
        ContextManager.shared.saveContextAndWait(context)

        let remote = try getRemoteService(for: post.blog)
        var remotePost: RemotePost
        do {
            remotePost = try await remote.post(withID: postID)
        } catch {
            if let error = error as? PostServiceRemoteError, error == .notFound {
                throw PostRepository.PostSaveError.deleted(title: post.titleForDisplay())
            } else {
                throw error
            }
        }

        // If the post is already in trash, do nothing. If the app were to
        // proceed with `/delete`, it would permanently delete the post.
        if remotePost.status != BasePost.Status.trash.rawValue {
            try await remote.deletePost(withID: postID)
        }

        post.status = .trash
        ContextManager.shared.saveContextAndWait(context)
    }

    /// Permanently delete the given post.
    @MainActor
    func delete(_ post: AbstractPost) async throws {
        wpAssert(post.isOriginal())

        let context = coreDataStack.mainContext
        guard let postID = post.postID, postID.intValue > 0 else {
            // The new sync system makes this situation impossible, but there
            // might exist posts from the previous versions of the app in this state.
            post.deleteAllRevisions()
            context.deleteObject(post)
            ContextManager.shared.saveContextAndWait(context)

            return wpAssertionFailure("Trying to patch a non-existent post")
        }
        try await getRemoteService(for: post.blog).deletePost(withID: postID.intValue)

        context.deleteObject(post)
        ContextManager.shared.saveContextAndWait(context)
    }

    /// Creates an autosave with the changes in the given revision.
    @MainActor
    func autosave(_ revision: AbstractPost) async throws -> RemotePostAutosaveResponse {
        assert(revision.isRevision())
        guard let remote = try getRemoteService(for: revision.blog) as? PostServiceRemoteREST else {
            throw Error.remoteAPIUnavailable
        }
        guard let postID = revision.postID?.intValue, postID > 0 else {
            wpAssertionFailure("missing post ID – programmer error")
            throw PostRepository.Error.missingPostID
        }
        let parameters = RemotePostCreateParameters(post: revision)
        return try await remote.createAutosave(forPostID: postID, parameters: parameters)
    }

    @MainActor
    func buildPageTree(pageIDs: [TaggedManagedObjectID<Page>]? = nil, request: NSFetchRequest<Page>? = nil) async throws -> [(pageID: TaggedManagedObjectID<Page>, hierarchyIndex: Int)] {
        assert(pageIDs != nil || request != nil, "`pageIDs` and `request` can not both be nil")

        let coreDataStack = ContextManager.shared
        return try await coreDataStack.performQuery { context in
            var pages = [Page]()

            if let pageIDs {
                pages = try pageIDs.map(context.existingObject(with:))
            } else if let request {
                pages = try context.fetch(request)
            }

            pages = pages.setHomePageFirst()

            // The `hierarchyIndex` is not a managed property, so it needs to be returend along with the page object id.
            return PageTree.hierarchyList(of: pages)
                .map { (TaggedManagedObjectID($0), $0.hierarchyIndex) }
        }
    }
}

private extension PostRepository {
    func getRemoteService(forblogID blogID: TaggedManagedObjectID<Blog>) async throws -> PostServiceRemoteExtended {
        let remote = try await coreDataStack.performQuery { [remoteFactory] context in
            let blog = try context.existingObject(with: blogID)
            return remoteFactory.forBlog(blog)
        }
        guard let remote = remote as? PostServiceRemoteExtended else {
            wpAssertionFailure("Expected the extended service to be available")
            throw PostRepository.Error.remoteAPIUnavailable
        }
        return remote
    }

    func getRemoteService(for blog: Blog) throws -> PostServiceRemoteExtended {
        guard let remote = remoteFactory.forBlog(blog) else {
            throw PostRepository.Error.remoteAPIUnavailable
        }
        guard let remote = remote as? PostServiceRemoteExtended else {
            wpAssertionFailure("Expected the extended service to be available")
            throw PostRepository.Error.remoteAPIUnavailable
        }
        return remote
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
    ///   - tag: Filter posts or pages with given tag.
    ///   - authorUserID: Filter posts or pages that are authored by given user.
    ///   - offset: The position of the paginated request. Pass 0 for the first page and count of already fetched results for following pages.
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
        tag: String?,
        authorUserID: NSNumber? = nil,
        offset: Int,
        limit: Int,
        orderBy: PostServiceResultsOrdering,
        descending: Bool,
        in blogID: TaggedManagedObjectID<Blog>
    ) async throws -> [TaggedManagedObjectID<P>] {
        try await fetch(
            type: type,
            searchInput: input,
            statuses: statuses,
            tag: tag,
            authorUserID: authorUserID,
            range: offset..<(offset + max(limit, 0)),
            orderBy: orderBy,
            descending: descending,
            deleteOtherLocalPosts: false,
            in: blogID
        )
    }

    /// Fetch all pages of the given site.
    ///
    /// It's higly recommended to cancel the returned task at an appropriate timing.
    ///
    /// - Warning: As the function name suggests, calling this function makes many API requests to fetch the site's
    ///     _all pages_. Fetching all pages may be handy in some use cases, but also can be wasteful when user aborts
    ///     in the middle of fetching all pages, if the fetching is not cancelled.
    ///
    /// - Parameters:
    ///   - statuses: Only fetch pages whose status is included in the given statues.
    ///   - blogID: Object ID of the site.
    /// - Returns: A `Task` instance representing the fetching. The fetch pages API requests will stop if the task is cancelled.
    func fetchAllPages(statuses: [BasePost.Status], authorUserID: NSNumber? = nil, in blogID: TaggedManagedObjectID<Blog>) -> Task<[TaggedManagedObjectID<Page>], Swift.Error> {
        Task {
            let pageSize = 100
            var allPages = [TaggedManagedObjectID<Page>]()
            while true {
                try Task.checkCancellation()

                let pageRange = allPages.count..<(allPages.count + pageSize)
                let current = try await fetch(
                    type: Page.self,
                    statuses: statuses,
                    authorUserID: authorUserID,
                    range: pageRange,
                    deleteOtherLocalPosts: false,
                    in: blogID
                )
                allPages.append(contentsOf: current)

                if current.isEmpty || current.count < pageSize {
                    break
                }
            }

            // Once all pages are fetched and saved, we need to purge local database
            // to ensure when a database query with the same conditions that are passed
            // to this function returns the same result as the `allPages` value.
            // Of course, we can't delete locally modified pages if there are any.
            try await coreDataStack.performAndSave { context in
                let request = Page.fetchRequest()
                // Delete posts that match _all of the following conditions_:
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    // belongs to the given blog
                    NSPredicate(format: "blog = %@", blogID.objectID),
                    // was fetched from the site
                    NSPredicate(format: "postID != NULL AND postID > 0"),
                    // doesn't have local edits
                    NSPredicate(format: "original = NULL AND revision = NULL"),
                    // is not included in the fetched page lists (i.e. it has been deleted from the site)
                    NSPredicate(format: "NOT (SELF IN %@)", allPages.map { $0.objectID }),
                    // we only need to deal with pages that match the filters passed to this function.
                    statuses.isEmpty ? nil : NSPredicate(format: "status IN %@", statuses),
                ].compactMap { $0 })

                try context.execute(NSBatchDeleteRequest(fetchRequest: request))
            }

            return allPages
        }
    }

    private func fetch<P: AbstractPost>(
        type: P.Type,
        searchInput: String? = nil,
        statuses: [BasePost.Status]?,
        tag: String? = nil,
        authorUserID: NSNumber?,
        range: Range<Int>,
        orderBy: PostServiceResultsOrdering = .byDate,
        descending: Bool = true,
        deleteOtherLocalPosts: Bool,
        in blogID: TaggedManagedObjectID<Blog>
    ) async throws -> [TaggedManagedObjectID<P>] {
        wpAssert(type == Post.self || type == Page.self, "Only support fetching Post or Page")
        wpAssert(range.lowerBound >= 0)

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

        let statuses = statuses?.map { $0.rawValue }
        let options = PostRepositoryPostsSerivceRemoteOptions(options: .init(
            statuses: statuses,
            number: range.count,
            offset: range.lowerBound,
            order: descending ? .descending : .ascending,
            orderBy: orderBy,
            authorID: authorUserID,
            search: searchInput,
            tag: tag
        ))
        let remotePosts = try await remote.getPosts(ofType: postType, options: options)

        let updatedPosts = try await coreDataStack.performAndSave { context in
            let updatedPosts = PostHelper.merge(
                remotePosts,
                ofType: postType,
                withStatuses: statuses,
                byAuthor: authorUserID,
                for: try context.existingObject(with: blogID),
                purgeExisting: deleteOtherLocalPosts,
                in: context
            )
            return updatedPosts.compactMap { aPost -> TaggedManagedObjectID<P>? in
                guard let post = aPost as? P else {
                    // FIXME: This issue is tracked in https://github.com/wordpress-mobile/WordPress-iOS/issues/22255
                    DDLogWarn("Expecting a \(postType) as \(type), but got \(aPost)")
                    return nil
                }
                return TaggedManagedObjectID(post)
            }
        }

        return updatedPosts
    }

}

private enum Strings {
    static let genericErrorMessage = NSLocalizedString("postList.genericErrorMessage", value: "Something went wrong", comment: "A generic error message title")
    static let errorUnsyncedChangesMessage = NSLocalizedString("postList.errorUnsyncedChangesMessage", value: "The app is uploading previously made changes to the server. Please try again later.", comment: "An error message")
}

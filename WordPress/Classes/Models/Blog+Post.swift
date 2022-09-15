import Foundation

// MARK: - Lookup posts

extension Blog {
    /// Lookup a post in the blog.
    ///
    /// - Parameter postID: The ID associated with the post.
    /// - Returns: The `AbstractPost` associated with the given post ID.
    @objc(lookupPostWithID:inContext:)
    func lookupPost(withID postID: NSNumber, in context: NSManagedObjectContext) -> AbstractPost? {
        lookupPost(withID: postID.int64Value, in: context)
    }

    /// Lookup a post in the blog.
    ///
    /// - Parameter postID: The ID associated with the post.
    /// - Returns: The `AbstractPost` associated with the given post ID.
    func lookupPost(withID postID: Int, in context: NSManagedObjectContext) -> AbstractPost? {
        lookupPost(withID: Int64(postID), in: context)
    }

    /// Lookup a post in the blog.
    ///
    /// - Parameter postID: The ID associated with the post.
    /// - Returns: The `AbstractPost` associated with the given post ID.
    func lookupPost(withID postID: Int64, in context: NSManagedObjectContext) -> AbstractPost? {
        let request = NSFetchRequest<AbstractPost>(entityName: NSStringFromClass(AbstractPost.self))
        request.predicate = NSPredicate(format: "blog = %@ AND original = NULL AND postID = %ld", self, postID)
        return (try? context.fetch(request))?.first
    }
}

// MARK: - Create posts

extension Blog {

    /// Create a post in the blog.
    @objc
    func createPost() -> Post {
        guard let context = managedObjectContext else {
            fatalError("The `Blog` instance is not associated with a `NSManagedObjectContext`")
        }

        let post = NSEntityDescription.insertNewObject(forEntityName: NSStringFromClass(Post.self), into: context) as! Post
        post.blog = self
        post.remoteStatus = .sync

        if let categoryID = settings?.defaultCategoryID,
            categoryID.intValue != PostCategoryUncategorized,
           let category = PostCategoryService(managedObjectContext: context).find(withBlogObjectID: objectID, andCategoryID: categoryID) {
            post.addCategoriesObject(category)
        }

        post.postFormat = settings?.defaultPostFormat
        post.postType = Post.typeDefaultIdentifier

        if let userID = userID, let author = getAuthorWith(id: userID) {
            post.authorID = author.userID
            post.author = author.displayName
        }

        try? context.obtainPermanentIDs(for: [post])
        precondition(!post.objectID.isTemporaryID, "The new post for this blog must have a permanent ObjectID")

        return post
    }

    /// Create a draft post in the blog.
    func createDraftPost() -> Post {
        let post = createPost()
        markAsDraft(post)
        return post
    }

    /// Create a page in the blog.
    @objc
    func createPage() -> Page {
        guard let context = managedObjectContext else {
            fatalError("The `Blog` instance is not associated with a `NSManagedObjectContext`")
        }

        let page = NSEntityDescription.insertNewObject(forEntityName: NSStringFromClass(Page.self), into: context) as! Page
        page.blog = self
        page.date_created_gmt = Date()
        page.remoteStatus = .sync

        if let userID = userID, let author = getAuthorWith(id: userID) {
            page.authorID = author.userID
            page.author = author.displayName
        }

        try? context.obtainPermanentIDs(for: [page])
        precondition(!page.objectID.isTemporaryID, "The new page for this blog must have a permanent ObjectID")

        return page
    }

    /// Create a draft page in the blog.
    func createDraftPage() -> Page {
        let page = createPage()
        markAsDraft(page)
        return page
    }

    private func markAsDraft(_ post: AbstractPost) {
        post.remoteStatus = .local
        post.dateModified = Date()
        post.status = .draft
    }
}

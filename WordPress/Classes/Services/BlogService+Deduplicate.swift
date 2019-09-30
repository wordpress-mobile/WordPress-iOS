import Foundation

extension BlogService {
    /// Removes any duplicate blogs in the given account
    ///
    /// We consider a blog to be a duplicate of another if they have the same dotComID.
    /// For each group of duplicate blogs, this will delete all but one, giving preference to
    /// blogs that have local drafts.
    ///
    /// If there's more than one blog in each group with local drafts, those will be reassigned
    /// to the remaining blog.
    ///
    @objc(deduplicateBlogsForAccount:)
    func deduplicateBlogs(for account: WPAccount) {
        // Group all the account blogs by ID so it's easier to find duplicates
        let blogsById = Dictionary(grouping: account.blogs, by: { $0.dotComID?.intValue ?? 0 })
        // For any group with more than one blog, remove duplicates
        for (blogID, group) in blogsById where group.count > 1 {
            assert(blogID > 0, "There should not be a Blog without ID if it has an account")
            guard blogID > 0 else {
                DDLogError("Found one or more WordPress.com blogs without ID, skipping de-duplication")
                continue
            }
            DDLogWarn("Found \(group.count - 1) duplicates for blog with ID \(blogID)")
            deduplicate(group: group)
        }
    }

    private func deduplicate(group: [Blog]) {
        // If there's a blog with local drafts, we'll preserve that one, otherwise we pick up the first
        // since we don't really care which blog to pick
        let candidateIndex = group.firstIndex(where: { !localDrafts(for: $0).isEmpty }) ?? 0
        let candidate = group[candidateIndex]

        // We look through every other blog
        for (index, blog) in group.enumerated() where index != candidateIndex {
            // If there are other blogs with local drafts, we reassing them to the blog that
            // is not going to be deleted
            for draft in localDrafts(for: blog) {
                DDLogInfo("Migrating local draft \(draft.postTitle ?? "<Untitled>") to de-duplicated blog")
                draft.blog = candidate
            }
            // Once the drafts are moved (if any), we can safely delete the duplicate
            DDLogInfo("Deleting duplicate blog \(blog.logDescription())")
            managedObjectContext.delete(blog)
        }
    }

    private func localDrafts(for blog: Blog) -> [AbstractPost] {
        // The original predicate from PostService.countPostsWithoutRemote() was:
        //   "postID = NULL OR postID <= 0"
        // Swift optionals make things a bit more verbose, but this should be equivalent
        return blog.posts?.filter({ (post) -> Bool in
            if let postID = post.postID?.intValue,
                postID > 0 {
                return false
            }
            return true
        }) ?? []
    }
}

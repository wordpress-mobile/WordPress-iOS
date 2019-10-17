@objc extension PostService {

    // MARK: - Updating the Remote Status

    /// Updates the post after an upload failure.
    ///
    /// Local-only pages will be reverted back to `.draft` to avoid scenarios like this:
    ///
    /// 1. A locally published page upload failed
    /// 2. The user presses the Page List's Retry button.
    /// 3. The page upload is retried and the page is **published**.
    ///
    /// This is an unexpected behavior and can be surprising for the user. We'd want the user to
    /// explicitly press on a “Publish” button instead.
    ///
    /// Posts' statuses are kept as is because we support automatic uploading of posts.
    ///
    /// - Important: This logic could have been placed in the setter for `remoteStatus`, but it's my belief
    ///     that our code will be much more resilient if we decouple the act of setting the `remoteStatus` value
    ///     and the logic behind processing an upload failure.  In fact I think the `remoteStatus` setter should
    ///     eventually be made private.
    /// - SeeAlso: PostCoordinator.resume
    ///
    func markAsFailedAndDraftIfNeeded(post: AbstractPost) {
        guard post.remoteStatus != .failed else {
            return
        }

        post.remoteStatus = .failed

        if !post.hasRemote() && post is Page {
            post.status = .draft
            post.dateModified = Date()
        }
    }
}

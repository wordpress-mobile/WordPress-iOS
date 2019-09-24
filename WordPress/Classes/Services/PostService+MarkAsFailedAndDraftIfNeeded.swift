@objc extension PostService {

    // MARK: - Updating the Remote Status
    /// Updates the post after an upload failure.
    ///
    /// - Important: This logic could have been placed in the setter for `remoteStatus`, but it's my belief
    ///     that our code will be much more resilient if we decouple the act of setting the `remoteStatus` value
    ///     and the logic behind processing an upload failure.  In fact I think the `remoteStatus` setter should
    ///     eventually be made private.
    ///
    func markAsFailedAndDraftIfNeeded(post: AbstractPost) {
        guard post.remoteStatus != .failed, !post.hasRemote() else {
            return
        }

        post.remoteStatus = .failed

        // If the post was not created on the server yet we convert the post to a local draft
        // with the current date. This post upload will be automatically retried later as a draft.
        //
        // However, if the post was supposed to be published or draft, we will leave it as is.
        // This is intentional because we currently want to automatically retry posts that
        // are either published or drafts. In the future, we will automatically retry all statuses.
        //
        // Automatic uploads happen in `PostCoordinator.resume()`.
        if !post.hasRemote() && post.status != .publish {
            // If the post was not created on the server yet we convert the post to a local draft post with the current date.
            post.status = .draft
            post.dateModified = Date()
        }
    }
}

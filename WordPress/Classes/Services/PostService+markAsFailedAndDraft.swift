@objc extension PostService {

    // MARK: - Updating the Remote Status
    /// Updates the post after an upload failure.
    ///
    /// - Important: This logic could have been placed in the setter for `remoteStatus`, but it's my belief
    ///     that our code will be much more resilient if we decouple the act of setting the `remoteStatus` value
    ///     and the logic behind processing an upload failure.  In fact I think the `remoteStatus` setter should
    ///     eventually be made private.
    ///
    func markAsFailedAndDraft(post: AbstractPost) {
        guard post.remoteStatus != .failed, !post.hasRemote() else {
            return
        }

        post.remoteStatus = .failed

        if !post.hasRemote() {
            // If the post was not created on the server yet we convert the post to a local draft post with the current date.
            post.status = .draft
            post.dateModified = Date()
        }
    }
}

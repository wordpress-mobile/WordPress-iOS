/// Encapsulates actions related to fetching reply comments.
///
extension CommentService {
    /// Fetches the current user's latest reply ID for the specified `parentID`.
    /// In case if there are no replies found, the success block will still be called with value 0.
    ///
    /// - Parameters:
    ///   - parentID: The ID of the parent comment.
    ///   - siteID: The ID of the site containing the parent comment.
    ///   - accountService: Service dependency to fetch the current user's dotcom ID.
    ///   - success: Closure called when the fetch succeeds.
    ///   - failure: Closure called when the fetch fails.
    func getLatestReplyID(for parentID: Int,
                          siteID: Int,
                          accountService: AccountService? = nil,
                          success: @escaping (Int) -> Void,
                          failure: @escaping (Error?) -> Void) {
        guard let remote = restRemote(forSite: NSNumber(value: siteID)) else {
            DDLogError("Unable to create a REST remote to fetch comment replies.")
            failure(nil)
            return
        }

        guard let userID = getCurrentUserID(accountService: accountService)?.intValue else {
            DDLogError("Unable to find the current user's dotcom ID to fetch comment replies.")
            failure(nil)
            return
        }

        // If the current user does not have permission to the site, the `author` endpoint parameter is not permitted.
        // Therefore, fetch all replies and filter for the current user here.
        remote.getCommentsV2(for: siteID, parameters: [.parent: parentID]) { remoteComments in
            // Filter for comments authored by the current user, and return the most recent commentID (if any).
            success(remoteComments
                        .filter { $0.authorID == userID }
                        .sorted { $0.date > $1.date }.first?.commentID ?? 0)
        } failure: { error in
            failure(error)
        }
    }

    /// Update the visibility of the comment's replies on the comment thread.
    /// Note that this only applies to comments fetched from the Reader Comments section (i.e. has a reference to the `ReaderPost`).
    ///
    /// - Parameters:
    ///   - ancestorComment: The ancestor comment that will have its reply comments iterated.
    ///   - completion: The block executed after the replies are updated.
    func updateRepliesVisibility(for ancestorComment: Comment, completion: (() -> Void)? = nil) {
        guard let context = ancestorComment.managedObjectContext,
              let post = ancestorComment.post as? ReaderPost,
              let comments = post.comments as? Set<Comment> else {
                  completion?()
                  return
              }

        let isVisible = (ancestorComment.status == CommentStatusType.approved.description)

        // iterate over the ancestor comment's descendants and update their visibility for the comment thread.
        //
        // the hierarchy property stores ancestral info by storing a string version of its comment ID hierarchy,
        // e.g.: "0000000012.0000000025.00000000035". The idea is to check if the ancestor comment's ID exists in the hierarchy.
        // as an optimization, skip checking the hierarchy when the comment is the direct child of the ancestor comment.
        context.perform {
            comments.filter { comment in
                comment.parentID == ancestorComment.commentID
                || comment.hierarchy
                    .split(separator: ".")
                    .compactMap({ Int32($0) })
                    .contains(ancestorComment.commentID)
            }.forEach { childComment in
                childComment.visibleOnReader = isVisible
            }

            ContextManager.shared.save(context)
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
}

private extension CommentService {
    /// Returns the current user's dotcom ID.
    ///
    /// - Parameter accountService: The service used to fetch the default `WPAccount`.
    /// - Returns: The current user's dotcom ID if exists, or nil otherwise.
    func getCurrentUserID(accountService: AccountService? = nil) -> NSNumber? {
        return try? WPAccount.lookupDefaultWordPressComAccount(in: managedObjectContext)?.userID
    }
}

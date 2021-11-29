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

        // also fill in the `author` parameter, so the remote only returns comments authored by the current user.
        remote.getCommentsV2(for: siteID, parameters: [.parent: parentID, .author: userID]) { remoteComments in
            // return the most recent commentID (if any).
            success(remoteComments.sorted { $0.date > $1.date }.first?.commentID ?? 0)
        } failure: { error in
            failure(error)
        }
    }
}

private extension CommentService {
    /// Returns the current user's dotcom ID.
    ///
    /// - Parameter accountService: The service used to fetch the default `WPAccount`.
    /// - Returns: The current user's dotcom ID if exists, or nil otherwise.
    func getCurrentUserID(accountService: AccountService? = nil) -> NSNumber? {
        let service = accountService ?? AccountService(managedObjectContext: managedObjectContext)
        return service.defaultWordPressComAccount()?.userID
    }
}

import Foundation

@objc extension ReaderSiteService {

    /// Block/unblock the specified site from appearing in the user's reader
    /// - Parameters:
    ///   - id: The ID of the site.
    ///   - blocked: Boolean value. `true` to block a site. `false` to unblock a site.
    ///   - success: Closure called when the request succeeds.
    ///   - failure: Closure called when the request fails.
    func flagSite(withID id: NSNumber, asBlocked blocked: Bool, success: (() -> Void)? = nil, failure: ((Error?) -> Void)? = nil) {
        let queryResult: (NSNumber, WordPressComRestApi)? = self.coreDataStack.performQuery({
            guard
                let defaultAccount = try? WPAccount.lookupDefaultWordPressComAccount(in: $0),
                let api = defaultAccount.wordPressComRestApi,
                api.hasCredentials()
            else {
                return nil
            }
            return (defaultAccount.userID, api)
        })

        guard let (userID, api) = queryResult else {
            failure?(self.errorForNotLoggedIn())
            return
        }

        // Optimistically flag the posts from the site being blocked.
        self.flagPosts(fromSite: id, asBlocked: blocked)

        // Flag site as blocked remotely
        let service = ReaderSiteServiceRemote(wordPressComRestApi: api)
        service.flagSite(withID: id.uintValue, asBlocked: blocked) {
            let properties: [String: Any] = [WPAppAnalyticsKeyBlogID: id]
            WPAnalytics.track(.readerSiteBlocked, withProperties: properties)
            self.coreDataStack.performAndSave({ context in
                self.flagSiteLocally(accountID: userID, siteID: id, asBlocked: blocked, in: context)
            }, completion: {
                success?()
            }, on: .main)
        } failure: { error in
            self.flagPosts(fromSite: id, asBlocked: !blocked)
            failure?(error)
        }
    }

    private func flagSiteLocally(accountID: NSNumber, siteID: NSNumber, asBlocked blocked: Bool, in context: NSManagedObjectContext) {
        if blocked {
            let blocked = BlockedSite.insert(into: context)
            blocked.accountID = accountID
            blocked.blogID = siteID
        } else {
            BlockedSite.delete(accountID: accountID, blogID: siteID, context: context)
        }
    }
}

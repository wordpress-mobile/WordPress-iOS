import Foundation

@objc extension ReaderSiteService {

    private var defaultAccount: WPAccount? {
        self.coreDataStack.performQuery { context in
            try? WPAccount.lookupDefaultWordPressComAccount(in: context)
        }
    }

    /// Block/unblock the specified site from appearing in the user's reader
    /// - Parameters:
    ///   - id: The ID of the site.
    ///   - blocked: Boolean value. `true` to block a site. `false` to unblock a site.
    ///   - success: Closure called when the request succeeds.
    ///   - failure: Closure called when the request fails.
    func flagSite(withID id: NSNumber, asBlocked blocked: Bool, success: (() -> Void)? = nil, failure: ((Error?) -> Void)? = nil) {
        guard let defaultAccount = defaultAccount, let api = defaultAccount.wordPressComRestApi, api.hasCredentials() else {
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
                self.flagSiteLocally(accountID: defaultAccount.userID, siteID: id, asBlocked: blocked, in: context)
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

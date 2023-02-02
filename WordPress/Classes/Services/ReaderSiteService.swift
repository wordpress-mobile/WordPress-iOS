import Foundation

@objc extension ReaderSiteService {

    private var defaultAccount: WPAccount? {
        let context = ContextManager.shared.mainContext
        do {
            let account = try WPAccount.lookupDefaultWordPressComAccount(in: context)
            return account
        } catch let error {
            DDLogError("Couldn't fetch default account: \(error.localizedDescription)")
            return nil
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
            self.flagSiteLocally(accountID: defaultAccount.userID, siteID: id, asBlocked: blocked)
            success?()
        } failure: { error in
            self.flagPosts(fromSite: id, asBlocked: !blocked)
            failure?(error)
        }
    }

    private func flagSiteLocally(accountID: NSNumber, siteID: NSNumber, asBlocked blocked: Bool) {
        let context = ContextManager.shared.mainContext
        if blocked {
            let blocked = BlockedSite.insert(into: context)
            blocked.accountID = accountID
            blocked.blogID = siteID
        } else {
            BlockedSite.delete(accountID: accountID, blogID: siteID, context: context)
        }
        do {
            try context.save()
        } catch let error {
            let operation = blocked ? "block" : "unblock"
            DDLogError("Couldn't \(operation) site: \(error.localizedDescription)")
        }
    }
}

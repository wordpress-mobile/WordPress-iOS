import Foundation


/// Encapsulates Account-Y Helpers
///
@objc class AccountHelper: NSObject {
    /// Threadsafe Helper that indicates whether a Default Dotcom Account is available, or not
    ///
    @objc static func isDotcomAvailable() -> Bool {
        return isDotcomAvailable(withValidToken: false)
    }

    @objc static func isDotcomAvailable(withValidToken: Bool = false) -> Bool {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        var defaultAccount: WPAccount? = nil

        context.performAndWait {
            defaultAccount = service.defaultWordPressComAccount()
        }

        guard let account = defaultAccount else {
            return false
        }

        if withValidToken {
            return account.authToken != nil
        } else {
            return true
        }
    }

    @objc static var isLoggedIn: Bool {
        get {
            return !(noSelfHostedBlogs && noWordPressDotComAccount)
        }
    }

    @objc static var noSelfHostedBlogs: Bool {
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)

        return blogService.blogCountSelfHosted() == 0 && blogService.hasAnyJetpackBlogs() == false
    }

    @objc static var noWordPressDotComAccount: Bool {
        return !AccountHelper.isDotcomAvailable()
    }
}

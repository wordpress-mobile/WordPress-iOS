import Foundation


/// Encapsulates Account-Y Helpers
///
@objc class AccountHelper: NSObject {
    /// Threadsafe Helper that indicates whether a Default Dotcom Account is available, or not
    ///
    @objc static func isDotcomAvailable() -> Bool {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        var available = false

        context.performAndWait {
            available = service.defaultWordPressComAccount() != nil
        }

        return available
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

    @discardableResult
    static func logBlogsAndAccounts(context: NSManagedObjectContext) -> String {
        let accountService = AccountService(managedObjectContext: context)
        let blogService = BlogService(managedObjectContext: context)
        let allBlogs = blogService.blogsForAllAccounts()
        let blogsByAccount = Dictionary(grouping: allBlogs, by: { $0.account })

        let defaultAccount = accountService.defaultWordPressComAccount()

        let accountCount = accountService.numberOfAccounts()
        let otherAccounts = accountCount > 1 ? " + \(accountCount) others" : ""
        let accountsDescription = "wp.com account: " + (defaultAccount?.logDescription ?? "<none>") + otherAccounts

        let blogTree = blogsByAccount.map({ (account, blogs) -> String in
            let accountDescription = account?.logDescription ?? "<Self-Hosted>"
            let isDefault = (account != nil && account == defaultAccount) ? " (default)" : ""
            let blogsDescription = blogs.map({ (blog) -> String in
                return "└─ " + blog.logDescription()
            }).joined(separator: "\n")

            return accountDescription + isDefault + "\n" + blogsDescription
        }).joined(separator: "\n")
        let blogTreeDescription = !blogsByAccount.isEmpty ? blogTree : "No account/blogs configured on device"

        let result = accountsDescription + "\nAll accounts and blogs:\n" + blogTreeDescription
        DDLogInfo(result)
        return result
    }
}

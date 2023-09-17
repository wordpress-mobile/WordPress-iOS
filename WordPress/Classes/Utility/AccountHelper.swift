import Foundation


/// Encapsulates Account-Y Helpers
///
@objc class AccountHelper: NSObject {
    /// Threadsafe Helper that indicates whether a Default Dotcom Account is available, or not
    ///
    @objc static func isDotcomAvailable() -> Bool {
        let context = ContextManager.sharedInstance().mainContext
        var available = false

        context.performAndWait {
            available = (try? WPAccount.lookupDefaultWordPressComAccount(in: context)) != nil
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
        return BlogQuery().hostedByWPCom(false).count(in: context) == 0 && (try? Blog.hasAnyJetpackBlogs(in: context)) == false
    }

    static var hasBlogs: Bool {
        let context = ContextManager.sharedInstance().mainContext
        return Blog.count(in: context) > 0
    }

    @objc static var noWordPressDotComAccount: Bool {
        return !AccountHelper.isDotcomAvailable()
    }

    static var defaultSiteId: NSNumber? {
        let context = ContextManager.sharedInstance().mainContext
        let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context)
        return account?.defaultBlog?.dotComID
    }

    static var authToken: String? {
        let context = ContextManager.sharedInstance().mainContext
        let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context)
        return account?.authToken
    }

    static func logBlogsAndAccounts(context: NSManagedObjectContext) {
        let allBlogs = (try? BlogQuery().blogs(in: context)) ?? []
        let blogsByAccount = Dictionary(grouping: allBlogs, by: { $0.account })

        let defaultAccount = try? WPAccount.lookupDefaultWordPressComAccount(in: context)

        let accountCount = (try? WPAccount.lookupNumberOfAccounts(in: context)) ?? 0
        let otherAccounts = accountCount > 1 ? " + \(accountCount - 1) others" : ""
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
    }

    static func logOutDefaultWordPressComAccount() {
        // Unschedule any scheduled blogging reminders
        let service = AccountService(coreDataStack: ContextManager.sharedInstance())

        // Unschedule any scheduled blogging reminders for the account's blogs.
        // We don't just clear all reminders, in case the user has self-hosted
        // sites added to the app.
        if let account = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext),
           let blogs = account.blogs,
           let scheduler = try? ReminderScheduleCoordinator() {
            blogs.forEach { scheduler.unschedule(for: $0) }
        }

        service.removeDefaultWordPressComAccount()

        deleteAccountData()
    }

    @objc static func deleteAccountData() {
        // Delete saved dashboard states
        BlogDashboardState.resetAllStates()

        // Delete local notification on logout
        PushNotificationsManager.shared.deletePendingLocalNotifications()

        // Also clear the spotlight index
        SearchManager.shared.deleteAllSearchableItems()

        // Delete donated user activities (e.g., for Siri Shortcuts)
        NSUserActivity.deleteAllSavedUserActivities {}

        // Refresh Remote Feature Flags
        WordPressAppDelegate.shared?.updateFeatureFlags()

        // Delete all the logs after logging out
        WPLogger.shared().deleteAllLogs()
    }
}

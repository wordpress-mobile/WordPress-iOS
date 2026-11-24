import WordPressData

class MySiteViewModel {

    let coreDataStack: CoreDataStack

    init(coreDataStack: CoreDataStack = ContextManager.shared) {
        self.coreDataStack = coreDataStack
    }

    var defaultAccount: WPAccount? {
        try? WPAccount.lookupDefaultWordPressComAccount(in: coreDataStack.mainContext)
    }

    /// The main blog for an account when none is selected.
    ///
    /// - Returns:the main blog for an account (last selected, or first blog in list).
    var mainBlog: Blog? {
        Blog.lastUsedOrFirst(in: coreDataStack.mainContext)
    }

    /// - Parameter showsSingleColumn: `true` when the site menu has no column of its own,
    ///   as on every iPhone. The dashboard is only the first screen in that layout.
    func getSection(
        for blog: Blog,
        jetpackFeaturesEnabled: Bool,
        showsSingleColumn: Bool
    ) -> MySiteViewController.Section {
        let shouldShowDashboard = jetpackFeaturesEnabled
        && blog.isAccessibleThroughWPCom
        && showsSingleColumn

        return shouldShowDashboard ? .dashboard : .siteMenu
    }
}

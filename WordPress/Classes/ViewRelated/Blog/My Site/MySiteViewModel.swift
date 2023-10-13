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

    func getSection(
        for blog: Blog,
        jetpackFeaturesEnabled: Bool,
        splitViewControllerIsHorizontallyCompact: Bool,
        isSplitViewEnabled: Bool
    ) -> MySiteViewController.Section {
        let shouldShowDashboard = jetpackFeaturesEnabled
        && blog.isAccessibleThroughWPCom()
        && (splitViewControllerIsHorizontallyCompact || !isSplitViewEnabled)

        return shouldShowDashboard ? .dashboard : .siteMenu
    }
}

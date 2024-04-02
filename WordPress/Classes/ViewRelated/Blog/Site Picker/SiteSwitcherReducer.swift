enum SiteSwitcherReducer {
    static func allBlogs() -> [Blog] {
        return dataSource().filteredBlogs
    }

    static func selectedBlog() -> Blog? {
        return RootViewCoordinator.sharedPresenter.currentOrLastBlog()
    }

    private static func dataSource() -> BlogListDataSource {
        // Utilize existing DataSource class to fetch blogs.
        let config = BlogListConfiguration.defaultConfig
        let dataSource = BlogListDataSource()
        dataSource.shouldHideSelfHostedSites = config.shouldHideSelfHostedSites
        dataSource.shouldHideBlogsNotSupportingDomains = config.shouldHideBlogsNotSupportingDomains
        return dataSource
    }
}

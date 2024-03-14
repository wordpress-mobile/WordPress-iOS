enum SiteSwitcherReducer {
    static func allBlogs() -> [Blog] {
        let config = BlogListConfiguration.defaultConfig
        let dataSource = BlogListDataSource()
        dataSource.shouldHideSelfHostedSites = config.shouldHideSelfHostedSites
        dataSource.shouldHideBlogsNotSupportingDomains = config.shouldHideBlogsNotSupportingDomains

        return dataSource.filteredBlogs
    }
}

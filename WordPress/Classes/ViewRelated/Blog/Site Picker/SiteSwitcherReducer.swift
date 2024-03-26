enum SiteSwitcherReducer {
    static func allBlogs() -> [Blog] {
        // Utilize existing DataSource class to fetch blogs.
        let config = BlogListConfiguration.defaultConfig
        let dataSource = BlogListDataSource()
        dataSource.shouldHideSelfHostedSites = config.shouldHideSelfHostedSites
        dataSource.shouldHideBlogsNotSupportingDomains = config.shouldHideBlogsNotSupportingDomains

        return dataSource.filteredBlogs
    }
}

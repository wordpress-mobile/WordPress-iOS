import SwiftUI

final class BlogListViewModel: ObservableObject {
    @Published var recentSites: [BlogListView.Site]
    @Published var pinnedSites: [BlogListView.Site]
    @Published var allRemainingSites: [BlogListView.Site]
    @Published var searchSites: [BlogListView.Site]

    private let contextManager: ContextManager
    private let dataSource: BlogListDataSource

    init(contextManager: ContextManager = ContextManager.sharedInstance()) {
        self.contextManager = contextManager
        self.dataSource = Self.createDataSource(contextManager: contextManager)
        pinnedSites = Self.filteredPinnedSites(allBlogs: dataSource.filteredBlogs)
        recentSites = Self.filteredRecentSites(allBlogs: dataSource.filteredBlogs)
        allRemainingSites = Self.filteredAllRemainingSites(allBlogs: dataSource.filteredBlogs)
        searchSites = dataSource.filteredBlogs.compactMap(BlogListView.Site.init)
    }

    private static func createDataSource(contextManager: ContextManager) -> BlogListDataSource {
        // Utilize existing DataSource class to fetch blogs.
        let config = BlogListConfiguration.defaultConfig
        let dataSource = BlogListDataSource(contextManager: contextManager)
        dataSource.shouldHideSelfHostedSites = config.shouldHideSelfHostedSites
        dataSource.shouldHideBlogsNotSupportingDomains = config.shouldHideBlogsNotSupportingDomains
        return dataSource
    }

    var allBlogs: [Blog] {
        return dataSource.filteredBlogs
    }

    func updateSearchText(_ newText: String) {
        if newText.isEmpty {
            searchSites = allBlogs.compactMap(BlogListView.Site.init)
        } else {
            searchSites = allBlogs
                .filter {
                    $0.url?.lowercased().contains(newText.lowercased()) == true
                    || $0.title?.lowercased().contains(newText.lowercased()) == true
                }
                .compactMap(BlogListView.Site.init)
        }
    }

    func togglePinnedSite(siteID: NSNumber?) {
        guard let blog = allBlogs.first(where: { $0.dotComID == siteID }) else {
            return
        }

        blog.pinnedDate = blog.pinnedDate == nil ? Date() : nil
        pinnedSites = Self.filteredPinnedSites(allBlogs: allBlogs)

        let beforeRecentsCount = recentSites.count
        recentSites = Self.filteredRecentSites(allBlogs: allBlogs)

        if recentSites.count == beforeRecentsCount {
            allRemainingSites = Self.filteredAllRemainingSites(allBlogs: allBlogs)
        }
        contextManager.saveContextAndWait(contextManager.mainContext)
    }

    func siteSelected(siteID: NSNumber?) {
        guard let blog = allBlogs.first(where: { $0.dotComID == siteID }) else {
            return
        }

        blog.lastUsed = Date()
        recentSites = Self.filteredRecentSites(allBlogs: allBlogs)
        contextManager.saveContextAndWait(contextManager.mainContext)
    }

    private static func filteredAllRemainingSites(allBlogs: [Blog]) -> [BlogListView.Site] {
        allBlogs.filter({ $0.pinnedDate == nil && $0.lastUsed == nil }).compactMap(BlogListView.Site.init)
    }

    private static func filteredRecentSites(allBlogs: [Blog]) -> [BlogListView.Site] {
        allBlogs
            .filter({ $0.pinnedDate == nil && $0.lastUsed != nil })
            .sorted(by: { $0.lastUsed! > $1.lastUsed! }) // Force-unwrapping due to the null check on line above
            .prefix(8)
            .compactMap(BlogListView.Site.init)
    }

    private static func filteredPinnedSites(allBlogs: [Blog]) -> [BlogListView.Site] {
        allBlogs
            .filter({ $0.pinnedDate != nil })
            .sorted(by: { $0.pinnedDate! > $1.pinnedDate! }) // Force-unwrapping due to the null check on line above
            .compactMap(BlogListView.Site.init)
    }

    private func selectedBlog() -> Blog? {
        return RootViewCoordinator.sharedPresenter.currentOrLastBlog()
    }
}

extension BlogListView.Site {
    init(blog: Blog) {
        self.init(
            id: blog.dotComID,
            title: blog.title ?? "",
            domain: blog.url ?? "",
            imageURL: blog.hasIcon ? URL(string: blog.icon!) : nil
        )
    }
}

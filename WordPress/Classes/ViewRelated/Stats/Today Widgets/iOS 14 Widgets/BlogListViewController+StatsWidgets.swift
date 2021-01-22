import WidgetKit

extension BlogListViewController {

    @objc func refreshStatsWidgetsSiteList() {

        guard let currentData = HomeWidgetTodayData.read() else {
            return
        }
        let blogService = BlogService(managedObjectContext: ContextManager.shared.mainContext)
        let updatedSiteList = blogService.visibleBlogsForWPComAccounts()

        let newData = updatedSiteList.reduce(into: [Int: HomeWidgetTodayData]()) { result, element in
            guard let blogID = element.dotComID else {
                return
            }
            let existingSite = currentData[blogID.intValue]

            let siteURL = element.url ?? existingSite?.url ?? ""
            let siteName = (element.title ?? siteURL).isEmpty ? siteURL : element.title ?? siteURL

            var iconURL = existingSite?.iconURL
            var timeZone = existingSite?.timeZone ?? TimeZone.current

            if let blog = blogService.blog(byBlogId: blogID) {
                iconURL = blog.icon
                timeZone = blogService.timeZone(for: blog)
            }
            let date = existingSite?.date ?? Date()
            let stats = existingSite?.stats ?? TodayWidgetStats()

            result[blogID.intValue] = HomeWidgetTodayData(siteID: blogID.intValue,
                                                          siteName: siteName,
                                                          iconURL: iconURL,
                                                          url: siteURL,
                                                          timeZone: timeZone,
                                                          date: date,
                                                          stats: stats)


        }

        HomeWidgetTodayData.write(items: newData)
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: WPHomeWidgetTodayKind)
        }
    }
}

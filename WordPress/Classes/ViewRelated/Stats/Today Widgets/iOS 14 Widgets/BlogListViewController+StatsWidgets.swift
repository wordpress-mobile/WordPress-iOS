import WidgetKit

extension BlogListViewController {

    @objc func refreshStatsWidgetsSiteList() {

        if let newTodayData = refreshStats(type: HomeWidgetTodayData.self) {
            HomeWidgetTodayData.write(items: newTodayData)

            if #available(iOS 14.0, *) {
                WidgetCenter.shared.reloadTimelines(ofKind: WPHomeWidgetTodayKind)
            }
        }

        if let newAllTimeData = refreshStats(type: HomeWidgetAllTimeData.self) {
            HomeWidgetAllTimeData.write(items: newAllTimeData)

            if #available(iOS 14.0, *) {
                WidgetCenter.shared.reloadTimelines(ofKind: WPHomeWidgetAllTimeKind)
            }
        }
    }

    private func refreshStats<T: HomeWidgetData>(type: T.Type) -> [Int: T]? {
        guard let currentData = T.read() else {
            return nil
        }
        let blogService = BlogService(managedObjectContext: ContextManager.shared.mainContext)
        let updatedSiteList = blogService.visibleBlogsForWPComAccounts()

        let newData = updatedSiteList.reduce(into: [Int: T]()) { sitesList, site in
            guard let blogID = site.dotComID else {
                return
            }
            let existingSite = currentData[blogID.intValue]

            let siteURL = site.url ?? existingSite?.url ?? ""
            let siteName = (site.title ?? siteURL).isEmpty ? siteURL : site.title ?? siteURL

            var timeZone = existingSite?.timeZone ?? TimeZone.current

            if let blog = Blog.lookup(withID: blogID, in: ContextManager.shared.mainContext) {
                timeZone = blog.timeZone
            }

            let date = existingSite?.date ?? Date()

            if type == HomeWidgetTodayData.self {

                let stats = (existingSite as? HomeWidgetTodayData)?.stats ?? TodayWidgetStats()

                sitesList[blogID.intValue] = HomeWidgetTodayData(siteID: blogID.intValue,
                                                                 siteName: siteName,
                                                                 url: siteURL,
                                                                 timeZone: timeZone,
                                                                 date: date,
                                                                 stats: stats) as? T
            } else if type == HomeWidgetAllTimeData.self {

                let stats = (existingSite as? HomeWidgetAllTimeData)?.stats ?? AllTimeWidgetStats()

                sitesList[blogID.intValue] = HomeWidgetAllTimeData(siteID: blogID.intValue,
                                                                   siteName: siteName,
                                                                   url: siteURL,
                                                                   timeZone: timeZone,
                                                                   date: date,
                                                                   stats: stats) as? T

            }
        }
        return newData
    }
}

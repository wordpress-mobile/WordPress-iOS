import WidgetKit


class StatsWidgetsStore {

    init() {
        observeAccountChangesForWidgets()
    }

    /// Refreshes the site list used to configure the widgets when sites are added or deleted
    @objc func refreshStatsWidgetsSiteList() {
        initializeStatsWidgetsIfNeeded()

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

        if let newThisWeekData = refreshStats(type: HomeWidgetThisWeekData.self) {
            HomeWidgetThisWeekData.write(items: newThisWeekData)

            if #available(iOS 14.0, *) {
                WidgetCenter.shared.reloadTimelines(ofKind: WPHomeWidgetThisWeekKind)
            }
        }
    }

    /// Initialize the local cache for widgets, if it does not exist
    func initializeStatsWidgetsIfNeeded() {
        guard #available(iOS 14.0, *) else {
            return
        }
        if HomeWidgetTodayData.read() == nil {
            DDLogInfo("StatsWidgets: Writing initialization data into HomeWidgetTodayData.plist")
            HomeWidgetTodayData.write(items: initializeHomeWidgetData(type: HomeWidgetTodayData.self))
            WidgetCenter.shared.reloadTimelines(ofKind: WPHomeWidgetTodayKind)
        }

        if HomeWidgetThisWeekData.read() == nil {
            DDLogInfo("StatsWidgets: Writing initialization data into HomeWidgetThisWeekData.plist")
            HomeWidgetThisWeekData.write(items: initializeHomeWidgetData(type: HomeWidgetThisWeekData.self))
            WidgetCenter.shared.reloadTimelines(ofKind: WPHomeWidgetThisWeekKind)
        }

        if HomeWidgetAllTimeData.read() == nil {
            DDLogInfo("StatsWidgets: Writing initialization data into HomeWidgetAllTimeData.plist")
            HomeWidgetAllTimeData.write(items: initializeHomeWidgetData(type: HomeWidgetAllTimeData.self))
            WidgetCenter.shared.reloadTimelines(ofKind: WPHomeWidgetAllTimeKind)
        }
    }

    /// Store stats in the widget cache
    /// - Parameters:
    ///   - widgetType: concrete type of the widget
    ///   - stats: stats to be stored
    func storeHomeWidgetData<T: HomeWidgetData>(widgetType: T.Type, stats: Codable) {
        guard #available(iOS 14.0, *),
              let siteID = SiteStatsInformation.sharedInstance.siteID else {
            return
        }

        var homeWidgetCache = T.read() ?? initializeHomeWidgetData(type: widgetType)
        guard let oldData = homeWidgetCache[siteID.intValue] else {
            DDLogError("StatsWidgets: Failed to find a matching site")
            return
        }

        guard let blog = Blog.lookup(withID: siteID, in: ContextManager.shared.mainContext) else {
            DDLogError("StatsWidgets: the site does not exist anymore")
            // if for any reason that site does not exist anymore, remove it from the cache.
            homeWidgetCache.removeValue(forKey: siteID.intValue)
            T.write(items: homeWidgetCache)
            return
        }
        var widgetKind = ""
        if widgetType == HomeWidgetTodayData.self, let stats = stats as? TodayWidgetStats {

            widgetKind = WPHomeWidgetTodayKind

            homeWidgetCache[siteID.intValue] = HomeWidgetTodayData(siteID: siteID.intValue,
                                                                   siteName: blog.title ?? oldData.siteName,
                                                                   url: blog.url ?? oldData.url,
                                                                   timeZone: blog.timeZone,
                                                                   date: Date(),
                                                                   stats: stats) as? T


        } else if widgetType == HomeWidgetAllTimeData.self, let stats = stats as? AllTimeWidgetStats {
            widgetKind = WPHomeWidgetAllTimeKind

            homeWidgetCache[siteID.intValue] = HomeWidgetAllTimeData(siteID: siteID.intValue,
                                                                     siteName: blog.title ?? oldData.siteName,
                                                                     url: blog.url ?? oldData.url,
                                                                     timeZone: blog.timeZone,
                                                                     date: Date(),
                                                                     stats: stats) as? T

        } else if widgetType == HomeWidgetThisWeekData.self, let stats = stats as? ThisWeekWidgetStats {

            homeWidgetCache[siteID.intValue] = HomeWidgetThisWeekData(siteID: siteID.intValue,
                                                                      siteName: blog.title ?? oldData.siteName,
                                                                      url: blog.url ?? oldData.url,
                                                                      timeZone: blog.timeZone,
                                                                      date: Date(),
                                                                      stats: stats) as? T
        }

        T.write(items: homeWidgetCache)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
}


// MARK: - Helper methods
private extension StatsWidgetsStore {

    // creates a list of days from the current date with empty stats to avoid showing an empty widget preview
    var initializedWeekdays: [ThisWeekWidgetDay] {
        var days = [ThisWeekWidgetDay]()
        for index in 0...7 {
            days.insert(ThisWeekWidgetDay(date: NSCalendar.current.date(byAdding: .day,
                                                                        value: -index,
                                                                        to: Date()) ?? Date(),
                                          viewsCount: 0,
                                          dailyChangePercent: 0),
                        at: index)
        }
        return days
    }

    func refreshStats<T: HomeWidgetData>(type: T.Type) -> [Int: T]? {
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

            } else if type == HomeWidgetThisWeekData.self {

                let stats = (existingSite as? HomeWidgetThisWeekData)?.stats ?? ThisWeekWidgetStats(days: initializedWeekdays)

                sitesList[blogID.intValue] = HomeWidgetThisWeekData(siteID: blogID.intValue,
                                                                    siteName: siteName,
                                                                    url: siteURL,
                                                                    timeZone: timeZone,
                                                                    date: date,
                                                                    stats: stats) as? T
            }
        }
        return newData
    }

    func initializeHomeWidgetData<T: HomeWidgetData>(type: T.Type) -> [Int: T] {
        let blogService = BlogService(managedObjectContext: ContextManager.shared.mainContext)

        return blogService.visibleBlogsForWPComAccounts().reduce(into: [Int: T]()) { result, element in
            if let blogID = element.dotComID,
               let url = element.url,
               let blog = Blog.lookup(withID: blogID, in: ContextManager.shared.mainContext) {
                // set the title to the site title, if it's not nil and not empty; otherwise use the site url
                let title = (element.title ?? url).isEmpty ? url : element.title ?? url
                let timeZone = blog.timeZone
                if type == HomeWidgetTodayData.self {
                    result[blogID.intValue] = HomeWidgetTodayData(siteID: blogID.intValue,
                                                                  siteName: title,
                                                                  url: url,
                                                                  timeZone: timeZone,
                                                                  date: Date(timeIntervalSinceReferenceDate: 0),
                                                                  stats: TodayWidgetStats()) as? T
                } else if type == HomeWidgetAllTimeData.self {
                    result[blogID.intValue] = HomeWidgetAllTimeData(siteID: blogID.intValue,
                                                                    siteName: title,
                                                                    url: url,
                                                                    timeZone: timeZone,
                                                                    date: Date(timeIntervalSinceReferenceDate: 0),
                                                                    stats: AllTimeWidgetStats()) as? T
                } else if type == HomeWidgetThisWeekData.self {
                    result[blogID.intValue] = HomeWidgetThisWeekData(siteID: blogID.intValue,
                                                                     siteName: title,
                                                                     url: url,
                                                                     timeZone: timeZone,
                                                                     date: Date(timeIntervalSinceReferenceDate: 0),
                                                                     stats: ThisWeekWidgetStats(days: initializedWeekdays)) as? T
                }
            }
        }
    }
}


// MARK: - Extract this week data
extension StatsWidgetsStore {
    func updateThisWeekHomeWidget(summary: StatsSummaryTimeIntervalData?) {
        guard #available(iOS 14.0, *) else {
            return
        }
        switch summary?.period {
        case .day:
            guard summary?.periodEndDate == StatsDataHelper.currentDateForSite().normalizedDate() else {
                return
            }
            let summaryData = Array(summary?.summaryData.reversed().prefix(ThisWeekWidgetStats.maxDaysToDisplay + 1) ?? [])

            let stats = ThisWeekWidgetStats(days: ThisWeekWidgetStats.daysFrom(summaryData: summaryData))
            StoreContainer.shared.statsWidgets.storeHomeWidgetData(widgetType: HomeWidgetThisWeekData.self, stats: stats)
        case .week:
            WidgetCenter.shared.reloadTimelines(ofKind: WPHomeWidgetThisWeekKind)
        default:
            break
        }
    }
}


// MARK: - Login/Logout notifications
private extension StatsWidgetsStore {

    func observeAccountChangesForWidgets() {
        guard #available(iOS 14.0, *) else {
            return
        }

        NotificationCenter.default.addObserver(forName: .WPAccountDefaultWordPressComAccountChanged,
                                               object: nil,
                                               queue: nil) { notification in

            if !AccountHelper.isLoggedIn {
                HomeWidgetTodayData.delete()
                HomeWidgetThisWeekData.delete()
                HomeWidgetAllTimeData.delete()
            }

            UserDefaults(suiteName: WPAppGroupName)?.setValue(AccountHelper.isLoggedIn, forKey: WPStatsHomeWidgetsUserDefaultsLoggedInKey)

            WidgetCenter.shared.reloadTimelines(ofKind: WPHomeWidgetTodayKind)
            WidgetCenter.shared.reloadTimelines(ofKind: WPHomeWidgetThisWeekKind)
            WidgetCenter.shared.reloadTimelines(ofKind: WPHomeWidgetAllTimeKind)
        }
    }
}


extension StatsViewController {
    @objc func initializeStatsWidgetsIfNeeded() {
        StoreContainer.shared.statsWidgets.initializeStatsWidgetsIfNeeded()
    }
}


extension BlogListViewController {
    @objc func refreshStatsWidgetsSiteList() {
        StoreContainer.shared.statsWidgets.refreshStatsWidgetsSiteList()
    }
}

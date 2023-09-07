import WidgetKit
import WordPressAuthenticator

class StatsWidgetsStore {
    private let coreDataStack: CoreDataStack

    init(coreDataStack: CoreDataStack = ContextManager.shared) {
        self.coreDataStack = coreDataStack

        updateJetpackFeaturesDisabled()
        observeAccountChangesForWidgets()
        observeAccountSignInForWidgets()
        observeApplicationLaunched()
        observeSiteUpdatesForWidgets()
        observeJetpackFeaturesState()
    }

    /// Refreshes the site list used to configure the widgets when sites are added or deleted
    @objc func refreshStatsWidgetsSiteList() {
        initializeStatsWidgetsIfNeeded()

        if let newTodayData = refreshStats(type: HomeWidgetTodayData.self) {
            HomeWidgetTodayData.write(items: newTodayData)
            WidgetCenter.shared.reloadTodayTimelines()
        }

        if let newAllTimeData = refreshStats(type: HomeWidgetAllTimeData.self) {
            HomeWidgetAllTimeData.write(items: newAllTimeData)
            WidgetCenter.shared.reloadAllTimeTimelines()
        }

        if let newThisWeekData = refreshStats(type: HomeWidgetThisWeekData.self) {
            HomeWidgetThisWeekData.write(items: newThisWeekData)
            WidgetCenter.shared.reloadThisWeekTimelines()
        }
    }

    /// Initialize the local cache for widgets, if it does not exist
    @objc func initializeStatsWidgetsIfNeeded() {
        UserDefaults(suiteName: WPAppGroupName)?.setValue(AccountHelper.defaultSiteId, forKey: AppConfiguration.Widget.Stats.userDefaultsSiteIdKey)

        if !HomeWidgetTodayData.cacheDataExists() {
            DDLogInfo("StatsWidgets: Writing initialization data into HomeWidgetTodayData.plist")
            HomeWidgetTodayData.write(items: initializeHomeWidgetData(type: HomeWidgetTodayData.self))
            WidgetCenter.shared.reloadTodayTimelines()
        }

        if !HomeWidgetThisWeekData.cacheDataExists() {
            DDLogInfo("StatsWidgets: Writing initialization data into HomeWidgetThisWeekData.plist")
            HomeWidgetThisWeekData.write(items: initializeHomeWidgetData(type: HomeWidgetThisWeekData.self))
            WidgetCenter.shared.reloadThisWeekTimelines()
        }

        if !HomeWidgetAllTimeData.cacheDataExists() {
            DDLogInfo("StatsWidgets: Writing initialization data into HomeWidgetAllTimeData.plist")
            HomeWidgetAllTimeData.write(items: initializeHomeWidgetData(type: HomeWidgetAllTimeData.self))
            WidgetCenter.shared.reloadAllTimeTimelines()
        }
    }

    /// Store stats in the widget cache
    /// - Parameters:
    ///   - widgetType: concrete type of the widget
    ///   - stats: stats to be stored
    func storeHomeWidgetData<T: HomeWidgetData>(widgetType: T.Type, stats: Codable) {
        guard let siteID = SiteStatsInformation.sharedInstance.siteID else {
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

        var widgetReload: (() -> ())?

        if widgetType == HomeWidgetTodayData.self, let stats = stats as? TodayWidgetStats {
            widgetReload = WidgetCenter.shared.reloadTodayTimelines

            homeWidgetCache[siteID.intValue] = HomeWidgetTodayData(siteID: siteID.intValue,
                                                                   siteName: blog.title ?? oldData.siteName,
                                                                   url: blog.url ?? oldData.url,
                                                                   timeZone: blog.timeZone,
                                                                   date: Date(),
                                                                   stats: stats) as? T


        } else if widgetType == HomeWidgetAllTimeData.self, let stats = stats as? AllTimeWidgetStats {
            widgetReload = WidgetCenter.shared.reloadAllTimeTimelines

            homeWidgetCache[siteID.intValue] = HomeWidgetAllTimeData(siteID: siteID.intValue,
                                                                     siteName: blog.title ?? oldData.siteName,
                                                                     url: blog.url ?? oldData.url,
                                                                     timeZone: blog.timeZone,
                                                                     date: Date(),
                                                                     stats: stats) as? T

        } else if widgetType == HomeWidgetThisWeekData.self, let stats = stats as? ThisWeekWidgetStats {
            widgetReload = WidgetCenter.shared.reloadThisWeekTimelines

            homeWidgetCache[siteID.intValue] = HomeWidgetThisWeekData(siteID: siteID.intValue,
                                                                      siteName: blog.title ?? oldData.siteName,
                                                                      url: blog.url ?? oldData.url,
                                                                      timeZone: blog.timeZone,
                                                                      date: Date(),
                                                                      stats: stats) as? T
        }

        T.write(items: homeWidgetCache)
        widgetReload?()
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
        let updatedSiteList = (try? BlogQuery().visible(true).hostedByWPCom(true).blogs(in: coreDataStack.mainContext)) ?? []

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
        let blogs = (try? BlogQuery().visible(true).hostedByWPCom(true).blogs(in: coreDataStack.mainContext)) ?? []
        return blogs.reduce(into: [Int: T]()) { result, element in
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
        switch summary?.period {
        case .day:
            guard summary?.periodEndDate == StatsDataHelper.currentDateForSite().normalizedDate() else {
                return
            }
            let summaryData = Array(summary?.summaryData.reversed().prefix(ThisWeekWidgetStats.maxDaysToDisplay + 1) ?? [])

            let stats = ThisWeekWidgetStats(days: ThisWeekWidgetStats.daysFrom(summaryData: summaryData))
            StoreContainer.shared.statsWidgets.storeHomeWidgetData(widgetType: HomeWidgetThisWeekData.self, stats: stats)
        case .week:
            WidgetCenter.shared.reloadThisWeekTimelines()
        default:
            break
        }
    }
}


// MARK: - Login/Logout notifications
private extension StatsWidgetsStore {
    /// Observes WPAccountDefaultWordPressComAccountChanged notification and reloads widget data based on the state of account.
    /// The site data is not yet loaded after this notification and widget data cannot be cached for newly signed in account.
    func observeAccountChangesForWidgets() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAccountChangedNotification), name: .WPAccountDefaultWordPressComAccountChanged, object: nil)
    }

    @objc func handleAccountChangedNotification() {
        let isLoggedIn = AccountHelper.isLoggedIn
        let userDefaults = UserDefaults(suiteName: WPAppGroupName)
        userDefaults?.setValue(isLoggedIn, forKey: AppConfiguration.Widget.Stats.userDefaultsLoggedInKey)

        guard !isLoggedIn else { return }

        HomeWidgetTodayData.delete()
        HomeWidgetThisWeekData.delete()
        HomeWidgetAllTimeData.delete()

        userDefaults?.setValue(nil, forKey: AppConfiguration.Widget.Stats.userDefaultsSiteIdKey)
        WidgetCenter.shared.reloadTodayTimelines()
        WidgetCenter.shared.reloadThisWeekTimelines()
        WidgetCenter.shared.reloadAllTimeTimelines()
    }

    /// Observes WPSigninDidFinishNotification and wordpressLoginFinishedJetpackLogin notifications and initializes the widget.
    /// The site data is loaded after this notification and widget data can be cached.
    func observeAccountSignInForWidgets() {
        NotificationCenter.default.addObserver(self, selector: #selector(initializeStatsWidgetsIfNeeded), name: NSNotification.Name(rawValue: WordPressAuthenticator.WPSigninDidFinishNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(initializeStatsWidgetsIfNeeded), name: .wordpressLoginFinishedJetpackLogin, object: nil)
    }

    /// Observes applicationLaunchCompleted notification and runs migration.
    func observeApplicationLaunched() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationLaunchCompleted), name: NSNotification.Name.applicationLaunchCompleted, object: nil)
    }

    @objc private func handleApplicationLaunchCompleted() {
        handleJetpackWidgetsMigration()
    }

    func observeJetpackFeaturesState() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateJetpackFeaturesDisabled),
                                               name: .WPAppUITypeChanged,
                                               object: nil)
    }

    @objc func updateJetpackFeaturesDisabled() {
        guard let defaults = UserDefaults(suiteName: WPAppGroupName) else {
            return
        }
        let key = AppConfiguration.Widget.Stats.userDefaultsJetpackFeaturesDisabledKey
        let oldValue = defaults.bool(forKey: key)
        let newValue = !JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled()
        defaults.setValue(newValue, forKey: key)
        if oldValue != newValue {
            refreshStatsWidgetsSiteList()
        }
    }
}

private extension StatsWidgetsStore {

    /// Handles migration to a Jetpack app version that started supporting Stats widgets.
    /// The required flags in shared UserDefaults are set and widgets are initialized.
    func handleJetpackWidgetsMigration() {
        // If user is logged in but defaultSiteIdKey is not set
        guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: coreDataStack.mainContext),
              let siteId = account.defaultBlog?.dotComID,
              let userDefaults = UserDefaults(suiteName: WPAppGroupName),
              userDefaults.value(forKey: AppConfiguration.Widget.Stats.userDefaultsSiteIdKey) == nil else {
            return
        }

        userDefaults.setValue(AccountHelper.isLoggedIn, forKey: AppConfiguration.Widget.Stats.userDefaultsLoggedInKey)
        userDefaults.setValue(siteId, forKey: AppConfiguration.Widget.Stats.userDefaultsSiteIdKey)
        initializeStatsWidgetsIfNeeded()
    }

    func observeSiteUpdatesForWidgets() {
        NotificationCenter.default.addObserver(self, selector: #selector(refreshStatsWidgetsSiteList), name: .WPSiteCreated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshStatsWidgetsSiteList), name: .WPSiteDeleted, object: nil)
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

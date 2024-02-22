import Foundation
import WordPressFlux

/// The view model used by Period Stats.
///

class SiteStatsPeriodViewModel: Observable {

    // MARK: - Properties

    let changeDispatcher = Dispatcher<Void>()

    private weak var periodDelegate: SiteStatsPeriodDelegate?
    private weak var referrerDelegate: SiteStatsReferrerDelegate?
    private let store: any StatsPeriodStoreProtocol
    private var lastRequestedDate: Date
    private var lastRequestedPeriod: StatsPeriodUnit
    private var periodReceipt: Receipt?
    private var changeReceipt: Receipt?
    private typealias Style = WPStyleGuide.Stats

    // MARK: - Constructor

    init(store: any StatsPeriodStoreProtocol = StoreContainer.shared.statsPeriod,
         selectedDate: Date,
         selectedPeriod: StatsPeriodUnit,
         periodDelegate: SiteStatsPeriodDelegate,
         referrerDelegate: SiteStatsReferrerDelegate) {
        self.periodDelegate = periodDelegate
        self.referrerDelegate = referrerDelegate
        self.store = store
        self.lastRequestedDate = StatsPeriodHelper().endDate(from: selectedDate, period: selectedPeriod)
        self.lastRequestedPeriod = selectedPeriod

        changeReceipt = store.onChange { [weak self] in
            self?.emitChange()
        }
    }

    func startFetchingOverview() {
        periodReceipt = store.query(
            .trafficOverviewData(
                .init(
                    date: lastRequestedDate,
                    period: lastRequestedPeriod,
                    chartBarsUnit: chartBarsUnit(from: lastRequestedPeriod),
                    chartBarsLimit: chartBarsLimit(for: lastRequestedPeriod),
                    chartTotalsLimit: chartTotalsLimit()
                )
            )
        )
    }

    func isFetchingChart() -> Bool {
        return store.isFetchingSummary
    }

    func fetchingFailed() -> Bool {
        return store.fetchingOverviewHasFailed
    }

    // MARK: - Table Model

    func tableViewModel() -> ImmuTable {
        if !store.containsCachedData && store.fetchingOverviewHasFailed {
            return ImmuTable.Empty
        }

        let errorBlock: (StatSection) -> [ImmuTableRow] = { section in
            return [StatsErrorRow(rowStatus: .error, statType: .period, statSection: section)]
        }
        let summaryErrorBlock: AsyncBlock<[ImmuTableRow]> = {
            return [StatsErrorRow(rowStatus: .error, statType: .period, statSection: nil)]
        }
        let loadingBlock: (StatSection) -> [ImmuTableRow] = { section in
            return [StatsGhostTopImmutableRow(statSection: section)]
        }

        var sections: [ImmuTableSection] = []
        switch lastRequestedPeriod {
        case .day:
            sections.append(.init(rows: blocks(for: .totalsSummary,
                                               type: .period,
                                               status: store.totalsSummaryStatus,
                                               block: { [weak self] in
                return self?.todayRows() ?? errorBlock(.periodToday)
            }, loading: {
                return loadingBlock(.periodToday)
            }, error: {
                return errorBlock(.periodToday)
            })))
        case .week, .month, .year:
            sections.append(.init(rows: blocks(for: .timeIntervalsSummary, .totalsSummary,
                                               type: .period,
                                               status: barChartFetchingStatus(),
                                               block: { [weak self] in
                return self?.barChartRows() ?? summaryErrorBlock()
            }, loading: {
                return [StatsGhostChartImmutableRow()]
            }, error: summaryErrorBlock)))
        }

        sections.append(.init(rows: blocks(for: .topPostsAndPages,
                                            type: .period,
                                            status: store.topPostsAndPagesStatus,
                                            block: { [weak self] in
                                                return self?.postsAndPagesTableRows() ?? errorBlock(.periodPostsAndPages)
            }, loading: {
                return loadingBlock(.periodPostsAndPages)
            }, error: {
                return errorBlock(.periodPostsAndPages)
        })))
        sections.append(.init(rows: blocks(for: .topReferrers,
                                            type: .period,
                                            status: store.topReferrersStatus,
                                            block: { [weak self] in
                                                return self?.referrersTableRows() ?? errorBlock(.periodReferrers)
            }, loading: {
                return loadingBlock(.periodReferrers)
            }, error: {
                return errorBlock(.periodReferrers)
        })))
        sections.append(.init(rows: blocks(for: .topClicks,
                                            type: .period,
                                            status: store.topClicksStatus,
                                            block: { [weak self] in
                                                return self?.clicksTableRows() ?? errorBlock(.periodClicks)
            }, loading: {
                return loadingBlock(.periodClicks)
            }, error: {
                return errorBlock(.periodClicks)
        })))
        sections.append(.init(rows: blocks(for: .topAuthors,
                                            type: .period,
                                            status: store.topAuthorsStatus,
                                            block: { [weak self] in
                                                return self?.authorsTableRows() ?? errorBlock(.periodAuthors)
            }, loading: {
                return loadingBlock(.periodAuthors)
            }, error: {
                return errorBlock(.periodAuthors)
        })))
        sections.append(.init(rows: blocks(for: .topCountries,
                                            type: .period,
                                            status: store.topCountriesStatus,
                                            block: { [weak self] in
                                                return self?.countriesTableRows() ?? errorBlock(.periodCountries)
            }, loading: {
                return loadingBlock(.periodCountries)
            }, error: {
                return errorBlock(.periodCountries)
        })))
        sections.append(.init(rows: blocks(for: .topSearchTerms,
                                            type: .period,
                                            status: store.topSearchTermsStatus,
                                            block: { [weak self] in
                                                return self?.searchTermsTableRows() ?? errorBlock(.periodSearchTerms)
            }, loading: {
                return loadingBlock(.periodSearchTerms)
            }, error: {
                return errorBlock(.periodSearchTerms)
        })))
        sections.append(.init(rows: blocks(for: .topPublished,
                                            type: .period,
                                            status: store.topPublishedStatus,
                                            block: { [weak self] in
                                                return self?.publishedTableRows() ?? errorBlock(.periodPublished)
            }, loading: {
                return loadingBlock(.periodPublished)
            }, error: {
                return errorBlock(.periodPublished)
        })))
        sections.append(.init(rows: blocks(for: .topVideos,
                                            type: .period,
                                            status: store.topVideosStatus,
                                            block: { [weak self] in
                                                return self?.videosTableRows() ?? errorBlock(.periodVideos)
            }, loading: {
                return loadingBlock(.periodVideos)
            }, error: {
                return errorBlock(.periodVideos)
        })))
        if SiteStatsInformation.sharedInstance.supportsFileDownloads {
            sections.append(.init(rows: blocks(for: .topFileDownloads,
                                                type: .period,
                                                status: store.topFileDownloadsStatus,
                                                block: { [weak self] in
                                                    return self?.fileDownloadsTableRows() ?? errorBlock(.periodFileDownloads)
                }, loading: {
                    return loadingBlock(.periodFileDownloads)
                }, error: {
                    return errorBlock(.periodFileDownloads)
            })))
        }

        return ImmuTable(sections: sections)
    }

    func barChartFetchingStatus() -> StoreFetchingStatus {
        switch (store.timeIntervalsSummaryStatus, store.totalsSummaryStatus) {
        case (.success, .success):
            return .success
        case (.loading, _), (_, .loading):
            return .loading
        case (.error, _), (_, .error):
            return .error
        default:
            return .idle
        }
    }

    // MARK: - Refresh Data

    func refreshTrafficOverviewData(withDate date: Date, forPeriod period: StatsPeriodUnit) {
        lastRequestedDate = StatsPeriodHelper().endDate(from: date, period: period)
        lastRequestedPeriod = period
        periodReceipt = nil
        periodReceipt = store.query(
            .trafficOverviewData(
                .init (
                    date: lastRequestedDate,
                    period: lastRequestedPeriod,
                    chartBarsUnit: chartBarsUnit(from: lastRequestedPeriod),
                    chartBarsLimit: chartBarsLimit(for: lastRequestedPeriod),
                    chartTotalsLimit: chartTotalsLimit()
                )
            )
        )
    }

    // MARK: - Chart Date

    func updateDate(forward: Bool) -> Date? {
        let increment = forward ? 1 : -1
        let nextDate = StatsDataHelper.calendar.date(byAdding: lastRequestedPeriod.calendarComponent, value: increment, to: lastRequestedDate)!
        return nextDate
    }
}

// MARK: - Private Extension

private extension SiteStatsPeriodViewModel {

    // MARK: - Create Table Rows

    func barChartRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()

        guard let summary = store.getSummary(), let barChartTotalsSummary = store.getTotalsSummary() else {
            return tableRows
        }

        let barChartDataSummary = boundChartData(summary, within: lastRequestedPeriod, and: lastRequestedDate)
        let periodDate = barChartDataSummary.periodEndDate
        let period = barChartDataSummary.period

        let viewsIntervalData = intervalData(summaryType: .views, totalsSummary: barChartTotalsSummary)
        let viewsTabData = StatsTrafficBarChartTabData(
            tabTitle: StatSection.periodOverviewViews.tabTitle,
            tabData: viewsIntervalData.count,
            difference: viewsIntervalData.difference,
            differencePercent: viewsIntervalData.percentage,
            date: periodDate,
            period: period
        )

        let visitorsIntervalData = intervalData(summaryType: .visitors, totalsSummary: barChartTotalsSummary)
        let visitorsTabData = StatsTrafficBarChartTabData(
            tabTitle: StatSection.periodOverviewVisitors.tabTitle,
            tabData: visitorsIntervalData.count,
            difference: visitorsIntervalData.difference,
            differencePercent: visitorsIntervalData.percentage,
            date: periodDate,
            period: period
        )

        let likesIntervalData = intervalData(summaryType: .likes, totalsSummary: barChartTotalsSummary)
        let likesTabData = StatsTrafficBarChartTabData(
            tabTitle: StatSection.periodOverviewLikes.tabTitle,
            tabData: likesIntervalData.count,
            difference: likesIntervalData.difference,
            differencePercent: likesIntervalData.percentage,
            date: periodDate,
            period: period
        )

        let commentsIntervalData = intervalData(summaryType: .comments, totalsSummary: barChartTotalsSummary)
        let commentsTabData = StatsTrafficBarChartTabData(
            tabTitle: StatSection.periodOverviewComments.tabTitle,
            tabData: commentsIntervalData.count,
            difference: commentsIntervalData.difference,
            differencePercent: commentsIntervalData.percentage,
            date: periodDate,
            period: period
        )

        var barChartData = [BarChartDataConvertible]()
        var barChartStyling = [StatsTrafficBarChartStyling]()
        let chart = StatsTrafficBarChart(data: barChartDataSummary)
        barChartData.append(contentsOf: chart.barChartData)
        barChartStyling.append(contentsOf: chart.barChartStyling)

        let row = StatsTrafficBarChartRow(
            action: nil,
            tabsData: [viewsTabData, visitorsTabData, likesTabData, commentsTabData],
            chartData: barChartData,
            chartStyling: barChartStyling,
            period: lastRequestedPeriod,
            unit: chartBarsUnit(from: lastRequestedPeriod),
            siteStatsPeriodDelegate: periodDelegate
        )

        tableRows.append(row)

        return tableRows
    }

    func boundChartData(_ data: StatsSummaryTimeIntervalData, within period: StatsPeriodUnit, and date: Date) -> StatsSummaryTimeIntervalData {
        let unit = chartBarsUnit(from: period)
        let summaryData = data.summaryData
        let currentDateComponents = StatsDataHelper.calendar.dateComponents([unit.calendarComponent, period.calendarComponent], from: date)

        let updatedSummaryData = summaryData.filter { summary in
            let summaryStartDateComponents = StatsDataHelper.calendar.dateComponents([unit.calendarComponent, period.calendarComponent], from: summary.periodStartDate)
            let summaryEndDate = StatsPeriodHelper().endDate(from: summary.periodStartDate, period: unit)
            let summaryEndDateComponents = StatsDataHelper.calendar.dateComponents([unit.calendarComponent, period.calendarComponent], from: summaryEndDate)
            switch period {
            case .day:
                return currentDateComponents.day == summaryStartDateComponents.day
                    || currentDateComponents.day == summaryEndDateComponents.day
            case .week:
                return currentDateComponents.weekOfYear == summaryStartDateComponents.weekOfYear
                    || currentDateComponents.weekOfYear == summaryEndDateComponents.weekOfYear
            case .month:
                return currentDateComponents.month == summaryStartDateComponents.month
                    || currentDateComponents.month == summaryEndDateComponents.month
            case .year:
                return currentDateComponents.year == summaryStartDateComponents.year
                    || currentDateComponents.year == summaryEndDateComponents.year
            }
        }

        return StatsSummaryTimeIntervalData(
            period: data.period,
            unit: data.unit,
            periodEndDate: data.periodEndDate,
            summaryData: updatedSummaryData
        )
    }

    func intervalData(summaryType: StatsSummaryType, totalsSummary: StatsSummaryTimeIntervalData?) -> (count: Int, difference: Int, percentage: Int) {
        guard let summaryData = totalsSummary?.summaryData, summaryData.count > 0 else {
            return (0, 0, 0)
        }

        let currentInterval = summaryData[summaryData.count - 1]
        let previousInterval = summaryData.count > 1 ? summaryData[summaryData.count - 2] : nil

        let currentCount: Int
        let previousCount: Int
        switch summaryType {
        case .views:
            currentCount = currentInterval.viewsCount
            previousCount = previousInterval?.viewsCount ?? 0
        case .visitors:
            currentCount = currentInterval.visitorsCount
            previousCount = previousInterval?.visitorsCount ?? 0
        case .likes:
            currentCount = currentInterval.likesCount
            previousCount = previousInterval?.likesCount ?? 0
        case .comments:
            currentCount = currentInterval.commentsCount
            previousCount = previousInterval?.commentsCount ?? 0
        }

        guard summaryData.count > 1 else {
            return (currentCount, 0, 0)
        }

        let difference = currentCount - previousCount
        var roundedPercentage = 0

        if previousCount > 0 {
            let percentage = (Float(difference) / Float(previousCount)) * 100
            roundedPercentage = Int(round(percentage))
        }

        return (currentCount, difference, roundedPercentage)
    }

    func todayRows() -> [ImmuTableRow] {
        let todaySummary = store.getTotalsSummary()?.summaryData.first
        let dataRows = [
            StatsTwoColumnRowData(
                leftColumnName: StatSection.periodOverviewViews.tabTitle,
                leftColumnData: (todaySummary?.viewsCount ?? 0).abbreviatedString(),
                rightColumnName: StatSection.periodOverviewVisitors.tabTitle,
                rightColumnData: (todaySummary?.visitorsCount ?? 0).abbreviatedString()
            ),
            StatsTwoColumnRowData(
                leftColumnName: StatSection.periodOverviewLikes.tabTitle,
                leftColumnData: (todaySummary?.likesCount ?? 0).abbreviatedString(),
                rightColumnName: StatSection.periodOverviewComments.tabTitle,
                rightColumnData: (todaySummary?.commentsCount ?? 0).abbreviatedString()
            )
        ]

        return [
            TwoColumnStatsRow(
                dataRows: dataRows,
                statSection: .periodToday,
                siteStatsInsightsDelegate: nil
            )
        ]
    }

    func postsAndPagesTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodPostsAndPages.itemSubtitle,
                                                 dataSubtitle: StatSection.periodPostsAndPages.dataSubtitle,
                                                 dataRows: postsAndPagesDataRows(),
                                                 statSection: StatSection.periodPostsAndPages,
                                                 siteStatsPeriodDelegate: periodDelegate))

        return tableRows
    }

    func postsAndPagesDataRows() -> [StatsTotalRowData] {
        let postsAndPages = store.getTopPostsAndPages()?.topPosts.prefix(10) ?? []

        return postsAndPages.map {
            let icon: UIImage?

            switch $0.kind {
            case .homepage:
                icon = Style.imageForGridiconType(.house, withTint: .icon)
            case .page:
                icon = Style.imageForGridiconType(.pages, withTint: .icon)
            case .post:
                icon = Style.imageForGridiconType(.posts, withTint: .icon)
            case .unknown:
                icon = Style.imageForGridiconType(.posts, withTint: .icon)
            }

            return StatsTotalRowData(name: $0.title,
                                     data: $0.viewsCount.abbreviatedString(),
                                     postID: $0.postID,
                                     dataBarPercent: Float($0.viewsCount) / Float(postsAndPages.first!.viewsCount),
                                     icon: icon,
                                     showDisclosure: true,
                                     disclosureURL: $0.postURL,
                                     statSection: .periodPostsAndPages)
        }
    }

    func referrersTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodReferrers.itemSubtitle,
                                                 dataSubtitle: StatSection.periodReferrers.dataSubtitle,
                                                 dataRows: referrersDataRows(),
                                                 statSection: StatSection.periodReferrers,
                                                 siteStatsPeriodDelegate: periodDelegate,
                                                 siteStatsReferrerDelegate: referrerDelegate))

        return tableRows
    }

    func referrersDataRows() -> [StatsTotalRowData] {
        let referrers = store.getTopReferrers()?.referrers.prefix(10) ?? []

        func rowDataFromReferrer(referrer: StatsReferrer) -> StatsTotalRowData {
            var icon: UIImage? = nil
            var iconURL: URL? = nil

            switch referrer.iconURL?.lastPathComponent {
            case "search-engine.png":
                icon = Style.imageForGridiconType(.search)
            case nil:
                icon = Style.imageForGridiconType(.globe)
            default:
                iconURL = referrer.iconURL
            }

            return StatsTotalRowData(name: referrer.title,
                                     data: referrer.viewsCount.abbreviatedString(),
                                     icon: icon,
                                     socialIconURL: iconURL,
                                     showDisclosure: true,
                                     disclosureURL: referrer.url,
                                     childRows: referrer.children.map { rowDataFromReferrer(referrer: $0) },
                                     statSection: .periodReferrers,
                                     isReferrerSpam: referrer.isSpam)
        }

        return referrers.map { rowDataFromReferrer(referrer: $0) }
    }

    func clicksTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodClicks.itemSubtitle,
                                                 dataSubtitle: StatSection.periodClicks.dataSubtitle,
                                                 dataRows: clicksDataRows(),
                                                 statSection: StatSection.periodClicks,
                                                 siteStatsPeriodDelegate: periodDelegate))

        return tableRows
    }

    func clicksDataRows() -> [StatsTotalRowData] {
        return store.getTopClicks()?.clicks.prefix(10).map { StatsTotalRowData(name: $0.title,
                                                                               data: $0.clicksCount.abbreviatedString(),
                                                                               showDisclosure: true,
                                                                               disclosureURL: $0.clickedURL,
                                                                               childRows: $0.children.map { StatsTotalRowData(name: $0.title,
                                                                                                                              data: $0.clicksCount.abbreviatedString(),
                                                                                                                              showDisclosure: true,
                                                                                                                              disclosureURL: $0.clickedURL)
            },
                                                                               statSection: .periodClicks) }
            ?? []
    }

    func authorsTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodAuthors.itemSubtitle,
                                                 dataSubtitle: StatSection.periodAuthors.dataSubtitle,
                                                 dataRows: authorsDataRows(),
                                                 statSection: StatSection.periodAuthors,
                                                 siteStatsPeriodDelegate: periodDelegate))

        return tableRows
    }

    func authorsDataRows() -> [StatsTotalRowData] {
        let authors = store.getTopAuthors()?.topAuthors.prefix(10) ?? []

        return authors.map { StatsTotalRowData(name: $0.name,
                                               data: $0.viewsCount.abbreviatedString(),
                                               dataBarPercent: Float($0.viewsCount) / Float(authors.first!.viewsCount),
                                               userIconURL: $0.iconURL,
                                               showDisclosure: true,
                                               childRows: $0.posts.map { StatsTotalRowData(name: $0.title, data: $0.viewsCount.abbreviatedString()) },
                                               statSection: .periodAuthors)
        }
    }

    func countriesTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        let map = countriesMap()
        let isMapShown = !map.data.isEmpty
        if isMapShown {
            tableRows.append(CountriesMapRow(countriesMap: map, statSection: .periodCountries))
        }
        tableRows.append(CountriesStatsRow(itemSubtitle: StatSection.periodCountries.itemSubtitle,
                                           dataSubtitle: StatSection.periodCountries.dataSubtitle,
                                           statSection: isMapShown ? nil : .periodCountries,
                                           dataRows: countriesDataRows(),
                                           siteStatsPeriodDelegate: periodDelegate))
        return tableRows
    }

    func countriesDataRows() -> [StatsTotalRowData] {
        return store.getTopCountries()?.countries.prefix(10).map { StatsTotalRowData(name: $0.name,
                                                                                     data: $0.viewsCount.abbreviatedString(),
                                                                                     icon: UIImage(named: $0.code),
                                                                                     statSection: .periodCountries) }
            ?? []
    }

    func countriesMap() -> CountriesMap {
        let countries = store.getTopCountries()?.countries ?? []
        return CountriesMap(minViewsCount: countries.last?.viewsCount ?? 0,
                            maxViewsCount: countries.first?.viewsCount ?? 0,
                            data: countries.reduce([String: NSNumber]()) { (dict, country) in
                                var nextDict = dict
                                nextDict.updateValue(NSNumber(value: country.viewsCount), forKey: country.code)
                                return nextDict
        })
    }

    func searchTermsTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodSearchTerms.itemSubtitle,
                                                 dataSubtitle: StatSection.periodSearchTerms.dataSubtitle,
                                                 dataRows: searchTermsDataRows(),
                                                 statSection: StatSection.periodSearchTerms,
                                                 siteStatsPeriodDelegate: periodDelegate))

        return tableRows
    }

    func searchTermsDataRows() -> [StatsTotalRowData] {
        guard let searchTerms = store.getTopSearchTerms() else {
            return []
        }

        var mappedSearchTerms = searchTerms.searchTerms.prefix(10).map { StatsTotalRowData(name: $0.term,
                                                                                           data: $0.viewsCount.abbreviatedString(),
                                                                                           statSection: .periodSearchTerms) }

        if !mappedSearchTerms.isEmpty && searchTerms.hiddenSearchTermsCount > 0 {
            // We want to insert the "Unknown search terms" item only if there's anything to show in the first place — if the
            // section is empty, it doesn't make sense to insert it here.

            let unknownSearchTerm = StatsTotalRowData(name: NSLocalizedString("Unknown search terms",
                                                                              comment: "Search Terms label for 'unknown search terms'."),
                                                      data: searchTerms.hiddenSearchTermsCount.abbreviatedString(),
                                                      statSection: .periodSearchTerms)

            mappedSearchTerms.insert(unknownSearchTerm, at: 0)
        }

        return mappedSearchTerms
    }

    func publishedTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(TopTotalsNoSubtitlesPeriodStatsRow(dataRows: publishedDataRows(),
                                                            statSection: StatSection.periodPublished,
                                                            siteStatsPeriodDelegate: periodDelegate))

        return tableRows
    }

    func publishedDataRows() -> [StatsTotalRowData] {
        return store.getTopPublished()?.publishedPosts.prefix(10).map { StatsTotalRowData.init(name: $0.title.stringByDecodingXMLCharacters(),
                                                                                               data: "",
                                                                                               showDisclosure: true,
                                                                                               disclosureURL: $0.postURL,
                                                                                               statSection: .periodPublished) }
            ?? []
    }

    func videosTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodVideos.itemSubtitle,
                                                 dataSubtitle: StatSection.periodVideos.dataSubtitle,
                                                 dataRows: videosDataRows(),
                                                 statSection: StatSection.periodVideos,
                                                 siteStatsPeriodDelegate: periodDelegate))

        return tableRows
    }

    func videosDataRows() -> [StatsTotalRowData] {
        return store.getTopVideos()?.videos.prefix(10).map { StatsTotalRowData(name: $0.title,
                                                                               data: $0.playsCount.abbreviatedString(),
                                                                               mediaID: $0.postID as NSNumber,
                                                                               icon: Style.imageForGridiconType(.video),
                                                                               showDisclosure: true,
                                                                               statSection: .periodVideos) }
            ?? []
    }

    func fileDownloadsTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodFileDownloads.itemSubtitle,
                                                 dataSubtitle: StatSection.periodFileDownloads.dataSubtitle,
                                                 dataRows: fileDownloadsDataRows(),
                                                 statSection: StatSection.periodFileDownloads,
                                                 siteStatsPeriodDelegate: periodDelegate))

        return tableRows
    }

    func fileDownloadsDataRows() -> [StatsTotalRowData] {
        return store.getTopFileDownloads()?.fileDownloads.prefix(10).map { StatsTotalRowData(name: $0.file,
                                                                                             data: $0.downloadCount.abbreviatedString(),
                                                                                             statSection: .periodFileDownloads) }
            ?? []
    }
}

private extension SiteStatsPeriodViewModel {
    /// - Returns: `StatsPeriodUnit` granularity of period data we want to receive from API
    private func chartBarsUnit(from period: StatsPeriodUnit) -> StatsPeriodUnit {
        switch period {
        case .day, .week:
            return .day
        case .month:
            return .week
        case .year:
            return .month
        }
    }

    /// - Returns: Number of bars data to fetch for a given Stats period
    private func chartBarsLimit(for period: StatsPeriodUnit) -> Int {
        switch period {
        case .day, .week:
            return 7
        case .month:
            return 5
        case .year:
            return 12
        }
    }

    /// - Returns: Number of totals summary data to fetch
    /// 1 is enough to optimize for speed if we don't show comparison label with other periods
    private func chartTotalsLimit() -> Int {
        return 1
    }
}

extension SiteStatsPeriodViewModel: AsyncBlocksLoadable {
    typealias CurrentStore = any StatsStoreCacheable
    typealias RowType = PeriodType

    var currentStore: any StatsStoreCacheable {
        store
    }

    func blocks<Value>(
        for blockType: RowType...,
        type: StatType,
        status: StoreFetchingStatus,
        checkingCache: CacheBlock? = nil,
        block: AsyncBlock<Value>,
        loading: AsyncBlock<Value>,
        error: AsyncBlock<Value>
    ) -> Value {
        let containsCachedData = checkingCache?() ?? blockType.allSatisfy { store.containsCachedData(for: $0) }

        if containsCachedData {
            return block()
        }

        switch status {
        case .loading, .idle:
            return loading()
        case .success:
            return block()
        case .error:
            return error()
        }
    }
}

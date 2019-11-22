import Foundation
import WordPressFlux

/// The view model used by Period Stats.
///

class SiteStatsPeriodViewModel: Observable {

    // MARK: - Properties

    let changeDispatcher = Dispatcher<Void>()
    var overviewStoreStatusOnChange: ((Status) -> Void)?

    private weak var periodDelegate: SiteStatsPeriodDelegate?
    private let store: StatsPeriodStore
    private var lastRequestedDate: Date
    private var lastRequestedPeriod: StatsPeriodUnit {
        didSet {
            if lastRequestedPeriod != oldValue {
                mostRecentChartData = nil
            }
        }
    }
    private var periodReceipt: Receipt?
    private var changeReceipt: Receipt?
    private typealias Style = WPStyleGuide.Stats

    weak var statsBarChartViewDelegate: StatsBarChartViewDelegate?

    private var mostRecentChartData: StatsSummaryTimeIntervalData? {
        didSet {
            if oldValue == nil {
                currentEntryIndex = (mostRecentChartData?.summaryData.endIndex ?? 0) - 1
            }
        }
    }

    private var currentEntryIndex: Int = 0

    // MARK: - Constructor

    init(store: StatsPeriodStore = StoreContainer.shared.statsPeriod,
         selectedDate: Date,
         selectedPeriod: StatsPeriodUnit,
         periodDelegate: SiteStatsPeriodDelegate) {
        self.periodDelegate = periodDelegate
        self.store = store
        self.lastRequestedDate = selectedDate
        self.lastRequestedPeriod = selectedPeriod

        changeReceipt = store.onChange { [weak self] in
            self?.emitChange()
        }

        store.cachedDataListener = { [weak self] hasCacheData in
            self?.overviewStoreStatusOnChange?(.fetchingCacheData(hasCacheData))
        }

        store.fetchingOverviewListener = { [weak self] fetching, success in
            let status: Status = fetching ? .fetchingData : .fetchingDataCompleted(success)
            self?.overviewStoreStatusOnChange?(status)
        }
    }

    func startFetchingOverview() {
        periodReceipt = store.query(.periods(date: lastRequestedDate, period: lastRequestedPeriod))
        store.actionDispatcher.dispatch(PeriodAction.refreshPeriodOverviewData(date: lastRequestedDate,
                                                                               period: lastRequestedPeriod,
                                                                               forceRefresh: true))
    }

    func isFetchingChart() -> Bool {
        return store.isFetchingSummary &&
            mostRecentChartData == nil
    }

    func fetchingFailed() -> Bool {
        return store.fetchingOverviewHasFailed
    }

    // MARK: - Table Model

    func tableViewModel() -> ImmuTable {

        var tableRows = [ImmuTableRow]()

        if Feature.enabled(.statsAsyncLoadingDWMY) {
            if !store.containsCachedData && store.fetchingOverviewHasFailed {
                return ImmuTable.Empty
            }
        } else {
            if !store.containsCachedData &&
                (store.fetchingOverviewHasFailed || store.isFetchingOverview) {
                return ImmuTable.Empty
            }
        }

        let errorBlock: (StatSection) -> [ImmuTableRow] = { section in
            return [CellHeaderRow(statSection: section),
                    StatsErrorRow(rowStatus: .error, statType: .period)]
        }
        let summaryErrorBlock: AsyncBlock<[ImmuTableRow]> = {
            return [PeriodEmptyCellHeaderRow(),
                    StatsErrorRow(rowStatus: .error, statType: .period)]
        }
        let loadingBlock: (StatSection) -> [ImmuTableRow] = { section in
            return [CellHeaderRow(statSection: section),
                    StatsGhostTopImmutableRow()]
        }

        tableRows.append(contentsOf: blocks(for: .summary,
                                            type: .period,
                                            status: store.summaryStatus,
                                            checkingCache: { [weak self] in
                                                return self?.mostRecentChartData != nil
            },
                                            block: { [weak self] in
                                                return self?.overviewTableRows() ?? summaryErrorBlock()
            }, loading: {
                return [PeriodEmptyCellHeaderRow(),
                        StatsGhostChartImmutableRow()]
        }, error: summaryErrorBlock))
        tableRows.append(contentsOf: blocks(for: .topPostsAndPages,
                                            type: .period,
                                            status: store.topPostsAndPagesStatus,
                                            block: { [weak self] in
                                                return self?.postsAndPagesTableRows() ?? errorBlock(.periodPostsAndPages)
            }, loading: {
                return loadingBlock(.periodPostsAndPages)
            }, error: {
                return errorBlock(.periodPostsAndPages)
        }))
        tableRows.append(contentsOf: blocks(for: .topReferrers,
                                            type: .period,
                                            status: store.topReferrersStatus,
                                            block: { [weak self] in
                                                return self?.referrersTableRows() ?? errorBlock(.periodReferrers)
            }, loading: {
                return loadingBlock(.periodReferrers)
            }, error: {
                return errorBlock(.periodReferrers)
        }))
        tableRows.append(contentsOf: blocks(for: .topClicks,
                                            type: .period,
                                            status: store.topClicksStatus,
                                            block: { [weak self] in
                                                return self?.clicksTableRows() ?? errorBlock(.periodClicks)
            }, loading: {
                return loadingBlock(.periodClicks)
            }, error: {
                return errorBlock(.periodClicks)
        }))
        tableRows.append(contentsOf: blocks(for: .topAuthors,
                                            type: .period,
                                            status: store.topAuthorsStatus,
                                            block: { [weak self] in
                                                return self?.authorsTableRows() ?? errorBlock(.periodAuthors)
            }, loading: {
                return loadingBlock(.periodAuthors)
            }, error: {
                return errorBlock(.periodAuthors)
        }))
        tableRows.append(contentsOf: blocks(for: .topCountries,
                                            type: .period,
                                            status: store.topCountriesStatus,
                                            block: { [weak self] in
                                                return self?.countriesTableRows() ?? errorBlock(.periodCountries)
            }, loading: {
                return loadingBlock(.periodCountries)
            }, error: {
                return errorBlock(.periodCountries)
        }))
        tableRows.append(contentsOf: blocks(for: .topSearchTerms,
                                            type: .period,
                                            status: store.topSearchTermsStatus,
                                            block: { [weak self] in
                                                return self?.searchTermsTableRows() ?? errorBlock(.periodSearchTerms)
            }, loading: {
                return loadingBlock(.periodSearchTerms)
            }, error: {
                return errorBlock(.periodSearchTerms)
        }))
        tableRows.append(contentsOf: blocks(for: .topPublished,
                                            type: .period,
                                            status: store.topPublishedStatus,
                                            block: { [weak self] in
                                                return self?.publishedTableRows() ?? errorBlock(.periodPublished)
            }, loading: {
                return loadingBlock(.periodPublished)
            }, error: {
                return errorBlock(.periodPublished)
        }))
        tableRows.append(contentsOf: blocks(for: .topVideos,
                                            type: .period,
                                            status: store.topVideosStatus,
                                            block: { [weak self] in
                                                return self?.videosTableRows() ?? errorBlock(.periodVideos)
            }, loading: {
                return loadingBlock(.periodVideos)
            }, error: {
                return errorBlock(.periodVideos)
        }))
        tableRows.append(contentsOf: blocks(for: .topFileDownloads,
                                            type: .period,
                                            status: store.topFileDownloadsStatus,
                                            block: { [weak self] in
                                                return self?.fileDownloadsTableRows() ?? errorBlock(.periodFileDownloads)
            }, loading: {
                return loadingBlock(.periodFileDownloads)
            }, error: {
                return errorBlock(.periodFileDownloads)
        }))

        tableRows.append(TableFooterRow())

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: tableRows)
            ])
    }

    // MARK: - Refresh Data

    func refreshPeriodOverviewData(withDate date: Date, forPeriod period: StatsPeriodUnit, resetOverviewCache: Bool = false) {
        if resetOverviewCache {
            mostRecentChartData = nil
        }

        lastRequestedDate = date
        lastRequestedPeriod = period
        ActionDispatcher.dispatch(PeriodAction.refreshPeriodOverviewData(date: date, period: period, forceRefresh: false))
    }

    // MARK: - State

    enum Status {
        case fetchingData
        case fetchingCacheData(_ hasCachedData: Bool)
        case fetchingDataCompleted(_ success: Bool)
    }

    // MARK: - Chart Date

    func chartDate(for entryIndex: Int) -> Date? {
        if let summaryData = mostRecentChartData?.summaryData,
            summaryData.indices.contains(entryIndex) {
            currentEntryIndex = entryIndex
            return summaryData[entryIndex].periodStartDate
        }
        return nil
    }

    func updateDate(forward: Bool) -> Date? {
        if forward {
            currentEntryIndex += 1
        } else {
            currentEntryIndex -= 1
        }
        return chartDate(for: currentEntryIndex)
    }
}

// MARK: - Private Extension

private extension SiteStatsPeriodViewModel {

    // MARK: - Create Table Rows

    func overviewTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(PeriodEmptyCellHeaderRow())

        let periodSummary = store.getSummary()
        let summaryData = periodSummary?.summaryData ?? []

        if mostRecentChartData == nil {
            mostRecentChartData = periodSummary
        } else if let mostRecentChartData = mostRecentChartData,
            let periodSummary = periodSummary,
            mostRecentChartData.periodEndDate == periodSummary.periodEndDate {
            self.mostRecentChartData = periodSummary
        } else if let periodSummary = periodSummary, let chartData = mostRecentChartData, periodSummary.periodEndDate > chartData.periodEndDate {
            mostRecentChartData = chartData
        }

        let periodDate = summaryData.last?.periodStartDate
        let period = periodSummary?.period

        let viewsData = intervalData(summaryType: .views)
        let viewsTabData = OverviewTabData(tabTitle: StatSection.periodOverviewViews.tabTitle,
                                           tabData: viewsData.count,
                                           difference: viewsData.difference,
                                           differencePercent: viewsData.percentage,
                                           date: periodDate,
                                           period: period,
                                           analyticsStat: .statsOverviewTypeTappedViews)

        let visitorsData = intervalData(summaryType: .visitors)
        let visitorsTabData = OverviewTabData(tabTitle: StatSection.periodOverviewVisitors.tabTitle,
                                              tabData: visitorsData.count,
                                              difference: visitorsData.difference,
                                              differencePercent: visitorsData.percentage,
                                              date: periodDate,
                                              period: period,
                                              analyticsStat: .statsOverviewTypeTappedVisitors)

        let likesData = intervalData(summaryType: .likes)
        // If Summary Likes is still loading, show dashes (instead of 0)
        // to indicate it's still loading.
        let likesLoadingStub = likesData.count > 0 ? nil : (store.isFetchingSummaryLikes ? "----" : nil)
        let likesTabData = OverviewTabData(tabTitle: StatSection.periodOverviewLikes.tabTitle,
                                           tabData: likesData.count,
                                           tabDataStub: likesLoadingStub,
                                           difference: likesData.difference,
                                           differencePercent: likesData.percentage,
                                           date: periodDate,
                                           period: period,
                                           analyticsStat: .statsOverviewTypeTappedLikes)

        let commentsData = intervalData(summaryType: .comments)
        let commentsTabData = OverviewTabData(tabTitle: StatSection.periodOverviewComments.tabTitle,
                                              tabData: commentsData.count,
                                              difference: commentsData.difference,
                                              differencePercent: commentsData.percentage,
                                              date: periodDate,
                                              period: period,
                                              analyticsStat: .statsOverviewTypeTappedComments)

        var barChartData = [BarChartDataConvertible]()
        var barChartStyling = [BarChartStyling]()
        var indexToHighlight: Int?
        if let chartData = mostRecentChartData {
            let chart = PeriodChart(data: chartData)

            barChartData.append(contentsOf: chart.barChartData)
            barChartStyling.append(contentsOf: chart.barChartStyling)

            indexToHighlight = chartData.summaryData.lastIndex(where: {
                lastRequestedDate.normalizedDate() >= $0.periodStartDate.normalizedDate()
            })
        }

        let row = OverviewRow(tabsData: [viewsTabData, visitorsTabData, likesTabData, commentsTabData],
                              chartData: barChartData, chartStyling: barChartStyling, period: lastRequestedPeriod, statsBarChartViewDelegate: statsBarChartViewDelegate, chartHighlightIndex: indexToHighlight)
        tableRows.append(row)

        return tableRows
    }

    func intervalData(summaryType: StatsSummaryType) -> (count: Int, difference: Int, percentage: Int) {
            guard let summaryData = mostRecentChartData?.summaryData,
                summaryData.indices.contains(currentEntryIndex) else {
                return (0, 0, 0)
            }

            let currentInterval = summaryData[currentEntryIndex]
            let previousInterval = currentEntryIndex >= 1 ? summaryData[currentEntryIndex-1] : nil

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

            let difference = currentCount - previousCount
            var roundedPercentage = 0

            if previousCount > 0 {
                let percentage = (Float(difference) / Float(previousCount)) * 100
                roundedPercentage = Int(round(percentage))
            }

            return (currentCount, difference, roundedPercentage)
    }

    func postsAndPagesTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(CellHeaderRow(statSection: StatSection.periodPostsAndPages))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodPostsAndPages.itemSubtitle,
                                                 dataSubtitle: StatSection.periodPostsAndPages.dataSubtitle,
                                                 dataRows: postsAndPagesDataRows(),
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
        tableRows.append(CellHeaderRow(statSection: StatSection.periodReferrers))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodReferrers.itemSubtitle,
                                                 dataSubtitle: StatSection.periodReferrers.dataSubtitle,
                                                 dataRows: referrersDataRows(),
                                                 siteStatsPeriodDelegate: periodDelegate))

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
                                     statSection: .periodReferrers)
        }

        return referrers.map { rowDataFromReferrer(referrer: $0) }
    }

    func clicksTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(CellHeaderRow(statSection: StatSection.periodClicks))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodClicks.itemSubtitle,
                                                 dataSubtitle: StatSection.periodClicks.dataSubtitle,
                                                 dataRows: clicksDataRows(),
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
        tableRows.append(CellHeaderRow(statSection: StatSection.periodAuthors))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodAuthors.itemSubtitle,
                                                 dataSubtitle: StatSection.periodAuthors.dataSubtitle,
                                                 dataRows: authorsDataRows(),
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
        tableRows.append(CellHeaderRow(statSection: StatSection.periodCountries))
        let map = countriesMap()
        if !map.data.isEmpty {
            tableRows.append(CountriesMapRow(countriesMap: map))
        }
        tableRows.append(CountriesStatsRow(itemSubtitle: StatSection.periodCountries.itemSubtitle,
                                           dataSubtitle: StatSection.periodCountries.dataSubtitle,
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
        tableRows.append(CellHeaderRow(statSection: StatSection.periodSearchTerms))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodSearchTerms.itemSubtitle,
                                                 dataSubtitle: StatSection.periodSearchTerms.dataSubtitle,
                                                 dataRows: searchTermsDataRows(),
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
        tableRows.append(CellHeaderRow(statSection: StatSection.periodPublished))
        tableRows.append(TopTotalsNoSubtitlesPeriodStatsRow(dataRows: publishedDataRows(),
                                                            siteStatsPeriodDelegate: periodDelegate))

        return tableRows
    }

    func publishedDataRows() -> [StatsTotalRowData] {
        return store.getTopPublished()?.publishedPosts.prefix(10).map { StatsTotalRowData.init(name: $0.title,
                                                                                               data: "",
                                                                                               showDisclosure: true,
                                                                                               disclosureURL: $0.postURL,
                                                                                               statSection: .periodPublished) }
            ?? []
    }

    func videosTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(CellHeaderRow(statSection: StatSection.periodVideos))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodVideos.itemSubtitle,
                                                 dataSubtitle: StatSection.periodVideos.dataSubtitle,
                                                 dataRows: videosDataRows(),
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
        tableRows.append(CellHeaderRow(statSection: StatSection.periodFileDownloads))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodFileDownloads.itemSubtitle,
                                                 dataSubtitle: StatSection.periodFileDownloads.dataSubtitle,
                                                 dataRows: fileDownloadsDataRows(),
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

extension SiteStatsPeriodViewModel: AsyncBlocksLoadable {
    typealias RowType = PeriodType

    var currentStore: StatsPeriodStore {
        return store
    }
}

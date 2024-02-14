import Foundation
import WordPressFlux

/// The view model used by Period Stats.
///

class SiteStatsPeriodViewModel: Observable {

    // MARK: - Properties

    let changeDispatcher = Dispatcher<Void>()

    private weak var periodDelegate: SiteStatsPeriodDelegate?
    private weak var referrerDelegate: SiteStatsReferrerDelegate?
    private let store: StatsPeriodStore
    private var selectedDate: Date
    private var lastRequestedDate: Date
    private var lastRequestedPeriod: StatsPeriodUnit
    private var periodReceipt: Receipt?
    private var changeReceipt: Receipt?
    private typealias Style = WPStyleGuide.Stats

    private let calendar: Calendar = .current

    // MARK: - Constructor

    init(store: StatsPeriodStore = StoreContainer.shared.statsPeriod,
         selectedDate: Date,
         selectedPeriod: StatsPeriodUnit,
         periodDelegate: SiteStatsPeriodDelegate,
         referrerDelegate: SiteStatsReferrerDelegate) {
        self.periodDelegate = periodDelegate
        self.referrerDelegate = referrerDelegate
        self.store = store
        self.selectedDate = selectedDate
        self.lastRequestedDate = Date()
        self.lastRequestedPeriod = selectedPeriod

        changeReceipt = store.onChange { [weak self] in
            self?.emitChange()
        }
    }

    func startFetchingOverview() {
        periodReceipt = store.query(
            .trafficOverviewData(
                date: lastRequestedDate,
                period: lastRequestedPeriod,
                unit: unit(from: lastRequestedPeriod),
                limit: limit(for: lastRequestedPeriod)
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

        sections.append(.init(rows: blocks(for: .timeIntervalsSummary,
                                            type: .period,
                                            status: barChartFetchingStatus(),
                                            block: { [weak self] in
                                                return self?.barChartRows() ?? summaryErrorBlock()
            }, loading: {
                return [StatsGhostChartImmutableRow()]
        }, error: summaryErrorBlock)))

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
        selectedDate = date
        lastRequestedPeriod = period
        periodReceipt = store.query(
            .trafficOverviewData(
                date: date,
                period: period,
                unit: unit(from: period),
                limit: limit(for: period)
            )
        )
    }

    // MARK: - Chart Date

    func updateDate(forward: Bool) -> Date? {
        let increment = forward ? 1 : -1
        let nextDate = calendar.date(byAdding: lastRequestedPeriod.calendarComponent, value: increment, to: selectedDate)!
        refreshTrafficOverviewData(withDate: nextDate, forPeriod: lastRequestedPeriod)
        return nextDate
    }
}

// MARK: - Private Extension

private extension SiteStatsPeriodViewModel {

    // MARK: - Create Table Rows

    func barChartRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()

        let chartSummary = store.getSummary()
        let chartSumaryData = chartSummary?.summaryData ?? []
        let totalsSummary = store.getTotalsSummary()
        let totalsSummaryData = totalsSummary != nil ? [totalsSummary!] : []

        let periodDate = chartSummary?.periodEndDate
        let period = chartSummary?.period

        let viewsTabData = StatsTrafficBarChartTabData(
            tabTitle: StatSection.periodOverviewViews.tabTitle,
            tabData: totalsSummaryData.first?.viewsCount ?? 0,
            difference: 0,
            differencePercent: 0,
            date: periodDate,
            period: period
        )

        let visitorsTabData = StatsTrafficBarChartTabData(
            tabTitle: StatSection.periodOverviewVisitors.tabTitle,
            tabData: totalsSummaryData.first?.visitorsCount ?? 0,
            difference: 0,
            differencePercent: 0,
            date: periodDate,
            period: period
        )

        let likesTabData = StatsTrafficBarChartTabData(
            tabTitle: StatSection.periodOverviewLikes.tabTitle,
            tabData: totalsSummaryData.first?.likesCount ?? 0,
            difference: 0,
            differencePercent: 0,
            date: periodDate,
            period: period
        )

        let commentsTabData = StatsTrafficBarChartTabData(
            tabTitle: StatSection.periodOverviewComments.tabTitle,
            tabData: totalsSummaryData.first?.commentsCount ?? 0,
            difference: 0,
            differencePercent: 0,
            date: periodDate,
            period: period
        )

        var barChartData = [BarChartDataConvertible]()
        var barChartStyling = [StatsTrafficBarChartStyling]()
        if let chartData = chartSummary {
            let chart = StatsTrafficBarChart(data: chartData)
            barChartData.append(contentsOf: chart.barChartData)
            barChartStyling.append(contentsOf: chart.barChartStyling)
        }

        let row = StatsTrafficBarChartRow(
            action: nil,
            tabsData: [viewsTabData, visitorsTabData, likesTabData, commentsTabData],
            chartData: barChartData,
            chartStyling: barChartStyling,
            period: unit(from: lastRequestedPeriod)
        )

        tableRows.append(row)

        return tableRows
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
    private func unit(from period: StatsPeriodUnit) -> StatsPeriodUnit {
        switch period {
        case .day, .week:
            return .day
        case .month:
            return .week
        case .year:
            return .month
        }
    }

    /// - Returns: Number of pieces of data for a given Stats period
    private func limit(for period: StatsPeriodUnit) -> Int {
        switch period {
        case .day, .week:
            return 7
        case .month:
            return 5
        case .year:
            return 12
        }
    }
}

extension SiteStatsPeriodViewModel: AsyncBlocksLoadable {
    typealias RowType = PeriodType

    var currentStore: StatsPeriodStore {
        return store
    }
}

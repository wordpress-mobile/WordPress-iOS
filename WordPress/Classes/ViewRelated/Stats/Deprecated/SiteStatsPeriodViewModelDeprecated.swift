import Foundation
import WordPressFlux

/// ℹ️ SiteStatsPeriodViewModelDeprecatedViewModel is an outdated version of Stats Period (Traffic) View Model
/// It's meant to be used when Stats Traffic Tab feature flag is disabled
/// All deprecated files should be removed once Stats Traffic Tab feature flag is removed

class SiteStatsPeriodViewModelDeprecated: Observable {

    // MARK: - Properties

    let changeDispatcher = Dispatcher<Void>()

    private weak var periodDelegate: SiteStatsPeriodDelegate?
    private weak var referrerDelegate: SiteStatsReferrerDelegate?
    private let store: StatsPeriodStore
    private var selectedDate: Date
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
                guard let mostRecentChartData = mostRecentChartData else {
                    return
                }

                currentEntryIndex = mostRecentChartData.summaryData.lastIndex(where: { $0.periodStartDate <= selectedDate })
                    ?? max(mostRecentChartData.summaryData.count - 1, 0)
            }
        }
    }

    private var currentEntryIndex: Int = 0

    private let calendar: Calendar = .current

    // MARK: - Constructor

    init(store: StatsPeriodStore = StatsPeriodStore(),
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
        periodReceipt = store.query(.allCachedPeriodData(date: lastRequestedDate, period: lastRequestedPeriod, unit: lastRequestedPeriod))
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

    func tableViewSnapshot() -> ImmuTableDiffableDataSourceSnapshot {
        var snapshot = ImmuTableDiffableDataSourceSnapshot()

        let emptySection = AnyHashable(0)
        snapshot.appendSections([emptySection])

        for tableSection in tableViewModel().sections {
            if let tableRows = tableSection.rows as? [any StatsHashableImmuTableRow] {
                let hashableRows = tableRows.map { AnyHashableImmuTableRow(immuTableRow: $0) }
                snapshot.appendItems(hashableRows, toSection: emptySection)
            }
        }

        return snapshot
    }

    private func tableViewModel() -> ImmuTable {

        var tableRows = [ImmuTableRow]()

        if !store.containsCachedData && store.fetchingOverviewHasFailed {
            return ImmuTable.Empty
        }

        let errorBlock: (StatSection) -> [ImmuTableRow] = { section in
            return [CellHeaderRow(statSection: section),
                    StatsErrorRow(rowStatus: .error, statType: .period, statSection: section, hideTitle: true)]
        }
        let summaryErrorBlock: AsyncBlock<[ImmuTableRow]> = {
            return [PeriodEmptyCellHeaderRow(statSection: .periodOverviewViews),
                    StatsErrorRow(rowStatus: .error, statType: .period, statSection: .periodOverviewViews, hideTitle: true)]
        }
        let loadingBlock: (StatSection) -> [ImmuTableRow] = { section in
            return [CellHeaderRow(statSection: section),
                    StatsGhostTopImmutableRow(statSection: section, hideTitle: true)]
        }

        tableRows.append(contentsOf: blocks(for: .timeIntervalsSummary,
                                            type: .period,
                                            status: store.timeIntervalsSummaryStatus,
                                            checkingCache: { [weak self] in
                                                return self?.mostRecentChartData != nil
            },
                                            block: { [weak self] in
                                                return self?.overviewTableRows() ?? summaryErrorBlock()
            }, loading: {
                return [PeriodEmptyCellHeaderRow(statSection: .periodOverviewViews),
                        StatsGhostChartImmutableRow(statSection: .periodOverviewViews)]
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
        if SiteStatsInformation.sharedInstance.supportsFileDownloads {
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
        }

        tableRows.append(TableFooterRow())

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: tableRows)
            ])
    }

    // MARK: - Refresh Data

    func refreshPeriodOverviewData(withDate date: Date, forPeriod period: StatsPeriodUnit) {
        selectedDate = date
        lastRequestedPeriod = period
        ActionDispatcher.dispatch(PeriodAction.refreshPeriodOverviewData(date: date, period: period, forceRefresh: true))
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

        guard let nextDate = chartDate(for: currentEntryIndex) else {
            // The date doesn't exist in the chart data... we need to manually calculate it and request
            // a refresh.
            let increment = forward ? 1 : -1
            let nextDate = calendar.date(byAdding: lastRequestedPeriod.calendarComponent, value: increment, to: selectedDate)!
            refreshPeriodOverviewData(withDate: nextDate, forPeriod: lastRequestedPeriod)
            return nextDate
        }

        return nextDate
    }
}

// MARK: - Private Extension

private extension SiteStatsPeriodViewModelDeprecated {

    // MARK: - Create Table Rows

    func overviewTableRows() -> [any StatsHashableImmuTableRow] {
        var tableRows = [any StatsHashableImmuTableRow]()
        tableRows.append(PeriodEmptyCellHeaderRow(statSection: .periodOverviewViews))

        let periodSummary = store.getSummary()
        let summaryData = periodSummary?.summaryData ?? []

        if mostRecentChartData == nil {
            mostRecentChartData = periodSummary
        } else if let mostRecentChartData = mostRecentChartData,
            let periodSummary = periodSummary,
            mostRecentChartData.periodEndDate == periodSummary.periodEndDate {
            self.mostRecentChartData = periodSummary
        } else if let periodSummary = periodSummary,   // when there is API data that has more recent API period date
                  let chartData = mostRecentChartData, // than our local chartData
                  periodSummary.periodEndDate > chartData.periodEndDate {

            // we validate if our periodDates match and if so we set the currentEntryIndex to the last index of the summaryData
            // fixes issue #19688
            if let lastSummaryDataEntry = summaryData.last,
               periodSummary.periodEndDate == lastSummaryDataEntry.periodStartDate {
                mostRecentChartData = periodSummary
                currentEntryIndex = summaryData.count - 1
            } else {
                mostRecentChartData = chartData
            }
        }

        let periodDate = summaryData.indices.contains(currentEntryIndex) ? summaryData[currentEntryIndex].periodStartDate : nil
        let period = periodSummary?.period

        let viewsData = intervalData(summaryType: .views)
        let viewsTabData = OverviewTabData(tabTitle: StatSection.periodOverviewViews.tabTitle,
                                           tabData: viewsData.count,
                                           difference: viewsData.difference,
                                           differencePercent: viewsData.percentage,
                                           date: periodDate,
                                           period: period,
                                           analyticsStat: .statsOverviewTypeTappedViews,
                                           accessibilityHint: StatSection.periodOverviewViews.tabAccessibilityHint)

        let visitorsData = intervalData(summaryType: .visitors)
        let visitorsTabData = OverviewTabData(tabTitle: StatSection.periodOverviewVisitors.tabTitle,
                                              tabData: visitorsData.count,
                                              difference: visitorsData.difference,
                                              differencePercent: visitorsData.percentage,
                                              date: periodDate,
                                              period: period,
                                              analyticsStat: .statsOverviewTypeTappedVisitors,
                                              accessibilityHint: StatSection.periodOverviewVisitors.tabAccessibilityHint)

        let likesData = intervalData(summaryType: .likes)
        // If Summary Likes is still loading, show dashes (instead of 0)
        // to indicate it's still loading.
        let likesLoadingStub = likesData.count > 0 ? nil : (store.isFetchingSummary ? "----" : nil)
        let likesTabData = OverviewTabData(tabTitle: StatSection.periodOverviewLikes.tabTitle,
                                           tabData: likesData.count,
                                           tabDataStub: likesLoadingStub,
                                           difference: likesData.difference,
                                           differencePercent: likesData.percentage,
                                           date: periodDate,
                                           period: period,
                                           analyticsStat: .statsOverviewTypeTappedLikes,
                                           accessibilityHint: StatSection.periodOverviewLikes.tabAccessibilityHint)

        let commentsData = intervalData(summaryType: .comments)
        let commentsTabData = OverviewTabData(tabTitle: StatSection.periodOverviewComments.tabTitle,
                                              tabData: commentsData.count,
                                              difference: commentsData.difference,
                                              differencePercent: commentsData.percentage,
                                              date: periodDate,
                                              period: period,
                                              analyticsStat: .statsOverviewTypeTappedComments,
                                              accessibilityHint: StatSection.periodOverviewComments.tabAccessibilityHint)

        var barChartData = [BarChartDataConvertible]()
        var barChartStyling = [BarChartStyling]()
        var indexToHighlight: Int?
        if let chartData = mostRecentChartData {
            let chart = PeriodChart(data: chartData)

            barChartData.append(contentsOf: chart.barChartData)
            barChartStyling.append(contentsOf: chart.barChartStyling)

            indexToHighlight = chartData.summaryData.lastIndex(where: {
                $0.periodStartDate.normalizedDate() <= selectedDate.normalizedDate()
            })
        }

        let row = OverviewRow(
            tabsData: [viewsTabData, visitorsTabData, likesTabData, commentsTabData],
            chartData: barChartData,
            chartStyling: barChartStyling,
            period: lastRequestedPeriod,
            statsBarChartViewDelegate: statsBarChartViewDelegate,
            chartHighlightIndex: indexToHighlight)
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

    func postsAndPagesTableRows() -> [any StatsHashableImmuTableRow] {
        var tableRows = [any StatsHashableImmuTableRow]()
        tableRows.append(CellHeaderRow(statSection: StatSection.periodPostsAndPages))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodPostsAndPages.itemSubtitle,
                                                 dataSubtitle: StatSection.periodPostsAndPages.dataSubtitle,
                                                 dataRows: postsAndPagesDataRows(),
                                                 statSection: .periodPostsAndPages,
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

    func referrersTableRows() -> [any StatsHashableImmuTableRow] {
        var tableRows = [any StatsHashableImmuTableRow]()
        tableRows.append(CellHeaderRow(statSection: StatSection.periodReferrers))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodReferrers.itemSubtitle,
                                                 dataSubtitle: StatSection.periodReferrers.dataSubtitle,
                                                 dataRows: referrersDataRows(),
                                                 statSection: .periodReferrers,
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

    func clicksTableRows() -> [any StatsHashableImmuTableRow] {
        var tableRows = [any StatsHashableImmuTableRow]()
        tableRows.append(CellHeaderRow(statSection: StatSection.periodClicks))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodClicks.itemSubtitle,
                                                 dataSubtitle: StatSection.periodClicks.dataSubtitle,
                                                 dataRows: clicksDataRows(),
                                                 statSection: .periodClicks,
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

    func authorsTableRows() -> [any StatsHashableImmuTableRow] {
        var tableRows = [any StatsHashableImmuTableRow]()
        tableRows.append(CellHeaderRow(statSection: StatSection.periodAuthors))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodAuthors.itemSubtitle,
                                                 dataSubtitle: StatSection.periodAuthors.dataSubtitle,
                                                 dataRows: authorsDataRows(),
                                                 statSection: .periodAuthors,
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

    func countriesTableRows() -> [any StatsHashableImmuTableRow] {
        var tableRows = [any StatsHashableImmuTableRow]()
        tableRows.append(CellHeaderRow(statSection: StatSection.periodCountries))
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

    func searchTermsTableRows() -> [any StatsHashableImmuTableRow] {
        var tableRows = [any StatsHashableImmuTableRow]()
        tableRows.append(CellHeaderRow(statSection: StatSection.periodSearchTerms))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodSearchTerms.itemSubtitle,
                                                 dataSubtitle: StatSection.periodSearchTerms.dataSubtitle,
                                                 dataRows: searchTermsDataRows(),
                                                 statSection: .periodSearchTerms,
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

    func publishedTableRows() -> [any StatsHashableImmuTableRow] {
        var tableRows = [any StatsHashableImmuTableRow]()
        tableRows.append(CellHeaderRow(statSection: StatSection.periodPublished))
        tableRows.append(TopTotalsNoSubtitlesPeriodStatsRow(dataRows: publishedDataRows(),
                                                            statSection: .periodPublished,
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

    func videosTableRows() -> [any StatsHashableImmuTableRow] {
        var tableRows = [any StatsHashableImmuTableRow]()
        tableRows.append(CellHeaderRow(statSection: StatSection.periodVideos))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodVideos.itemSubtitle,
                                                 dataSubtitle: StatSection.periodVideos.dataSubtitle,
                                                 dataRows: videosDataRows(),
                                                 statSection: .periodVideos,
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

    func fileDownloadsTableRows() -> [any StatsHashableImmuTableRow] {
        var tableRows = [any StatsHashableImmuTableRow]()
        tableRows.append(CellHeaderRow(statSection: StatSection.periodFileDownloads))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodFileDownloads.itemSubtitle,
                                                 dataSubtitle: StatSection.periodFileDownloads.dataSubtitle,
                                                 dataRows: fileDownloadsDataRows(),
                                                 statSection: .periodFileDownloads,
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

extension SiteStatsPeriodViewModelDeprecated: AsyncBlocksLoadable {
    typealias RowType = PeriodType

    var currentStore: StatsPeriodStore {
        return store
    }
}

import Foundation
import WordPressFlux

struct StatsTrafficSection: Hashable {
    let periodType: PeriodType

    init(periodType: PeriodType) {
        self.periodType = periodType
    }
}

final class SiteStatsPeriodViewModel: Observable {

    // MARK: - Properties

    let changeDispatcher = Dispatcher<Void>()

    private weak var periodDelegate: SiteStatsPeriodDelegate?
    private weak var referrerDelegate: SiteStatsReferrerDelegate?
    private let store: any StatsPeriodStoreProtocol
    private var lastRequestedDate: Date
    private var lastRequestedPeriod: StatsPeriodUnit {
        didSet {
            SiteStatsDashboardPreferences.setSelected(periodUnit: lastRequestedPeriod)
        }
    }
    private var periodReceipt: Receipt?
    private var changeReceipt: Receipt?
    private typealias Style = WPStyleGuide.Stats

    weak var statsBarChartViewDelegate: StatsBarChartViewDelegate?

    private var mostRecentChartData: StatsSummaryTimeIntervalData? {
        didSet {
            if oldValue == nil {
                guard let mostRecentChartData else {
                    return
                }

                currentEntryIndex = mostRecentChartData.summaryData.lastIndex(where: { $0.periodStartDate <= lastRequestedDate })
                    ?? max(mostRecentChartData.summaryData.count - 1, 0)
            }
        }
    }

    private var currentEntryIndex: Int = 0
    var currentTabIndex: Int = 0

    // MARK: - Constructor

    init(store: any StatsPeriodStoreProtocol = StatsPeriodStore(),
         selectedDate: Date,
         selectedPeriod: StatsPeriodUnit,
         periodDelegate: SiteStatsPeriodDelegate,
         referrerDelegate: SiteStatsReferrerDelegate) {
        self.periodDelegate = periodDelegate
        self.referrerDelegate = referrerDelegate
        self.store = store
        self.lastRequestedDate = StatsPeriodHelper().endDate(from: selectedDate, period: selectedPeriod)
        self.lastRequestedPeriod = selectedPeriod
    }

    func refreshTrafficOverviewData(withDate date: Date, forPeriod period: StatsPeriodUnit) {
        if period != lastRequestedPeriod {
            currentEntryIndex = 0
            mostRecentChartData = nil
        }
        lastRequestedPeriod = period
        lastRequestedDate = StatsPeriodHelper().endDate(from: date, period: period)
        currentEntryIndex = entryIndex(for: lastRequestedDate)

        periodReceipt = nil
        periodReceipt = store.query(
            .trafficOverviewData(
                .init(
                    date: lastRequestedDate,
                    period: lastRequestedPeriod,
                    chartBarsUnit: chartBarsUnit(from: lastRequestedPeriod),
                    chartBarsLimit: chartBarsLimit(for: lastRequestedPeriod)
                )
            )
        )
    }

    // MARK: - Listeners

    func addListeners() {
        changeReceipt = store.onChange { [weak self] in
            self?.emitChange()
        }
    }

    func removeListeners() {
        changeReceipt = nil
        periodReceipt = nil
    }

    // MARK: - Loading

    func fetchingFailed() -> Bool {
        return store.fetchingOverviewHasFailed
    }

    // MARK: - Table Model

    func tableViewSnapshot() -> ImmuTableDiffableDataSourceSnapshot {
        var snapshot = ImmuTableDiffableDataSourceSnapshot()
        if !store.containsCachedData && store.fetchingOverviewHasFailed {
            return snapshot
        }

        let errorBlock: (StatSection) -> [any StatsHashableImmuTableRow] = { section in
            return [StatsErrorRow(rowStatus: .error, statType: .period, statSection: section)]
        }
        let summaryErrorBlock: AsyncBlock<[any StatsHashableImmuTableRow]> = {
            return [StatsErrorRow(rowStatus: .error, statType: .period, statSection: .periodOverviewViews)]
        }
        let loadingBlock: (StatSection) -> [any StatsHashableImmuTableRow] = { section in
            return [StatsGhostTopImmutableRow(statSection: section)]
        }

        let overviewSection = StatsTrafficSection(periodType: .timeIntervalsSummary)
        let overviewRows = blocks(for: .timeIntervalsSummary,
                                  type: .period,
                                  status: store.timeIntervalsSummaryStatus,
                                  checkingCache: { [weak self] in
            return self?.mostRecentChartData != nil
        },
                                  block: { [weak self] in
            return self?.overviewTableRows() ?? summaryErrorBlock()
        }, loading: {
            return [StatsGhostChartImmutableRow()]
        }, error: {
            return summaryErrorBlock()
        })
            .map { AnyHashableImmuTableRow(immuTableRow: $0) }
        snapshot.appendSections([overviewSection])
        snapshot.appendItems(overviewRows, toSection: overviewSection)

        let topPostsAndPagesSection = StatsTrafficSection(periodType: .topPostsAndPages)
        let topPostsAndPagesRows = blocks(for: .topPostsAndPages,
                                          type: .period,
                                          status: store.topPostsAndPagesStatus,
                                          block: { [weak self] in
            return self?.postsAndPagesTableRows() ?? errorBlock(.periodPostsAndPages)
        }, loading: {
            return loadingBlock(.periodPostsAndPages)
        }, error: {
            return errorBlock(.periodPostsAndPages)
        })
            .map { AnyHashableImmuTableRow(immuTableRow: $0) }
        snapshot.appendSections([topPostsAndPagesSection])
        snapshot.appendItems(topPostsAndPagesRows, toSection: topPostsAndPagesSection)

        let topReferrersSection = StatsTrafficSection(periodType: .topReferrers)
        let topReferrersRows = blocks(for: .topReferrers,
                                      type: .period,
                                      status: store.topReferrersStatus,
                                      block: { [weak self] in
            return self?.referrersTableRows() ?? errorBlock(.periodReferrers)
        }, loading: {
            return loadingBlock(.periodReferrers)
        }, error: {
            return errorBlock(.periodReferrers)
        })
            .map { AnyHashableImmuTableRow(immuTableRow: $0) }
        snapshot.appendSections([topReferrersSection])
        snapshot.appendItems(topReferrersRows, toSection: topReferrersSection)

        let topClicksSection = StatsTrafficSection(periodType: .topClicks)
        let topClicksRows = blocks(for: .topClicks,
                                   type: .period,
                                   status: store.topClicksStatus,
                                   block: { [weak self] in
            return self?.clicksTableRows() ?? errorBlock(.periodClicks)
        }, loading: {
            return loadingBlock(.periodClicks)
        }, error: {
            return errorBlock(.periodClicks)
        })
            .map { AnyHashableImmuTableRow(immuTableRow: $0) }
        snapshot.appendSections([topClicksSection])
        snapshot.appendItems(topClicksRows, toSection: topClicksSection)

        let topAuthorsSection = StatsTrafficSection(periodType: .topAuthors)
        let topAuthorsRows = blocks(for: .topAuthors,
                                    type: .period,
                                    status: store.topAuthorsStatus,
                                    block: { [weak self] in
            return self?.authorsTableRows() ?? errorBlock(.periodAuthors)
        }, loading: {
            return loadingBlock(.periodAuthors)
        }, error: {
            return errorBlock(.periodAuthors)
        })
            .map { AnyHashableImmuTableRow(immuTableRow: $0) }
        snapshot.appendSections([topAuthorsSection])
        snapshot.appendItems(topAuthorsRows, toSection: topAuthorsSection)

        let topCountriesSection = StatsTrafficSection(periodType: .topCountries)
        let topCountriesRows = blocks(for: .topCountries,
                                      type: .period,
                                      status: store.topCountriesStatus,
                                      block: { [weak self] in
            return self?.countriesTableRows() ?? errorBlock(.periodCountries)
        }, loading: {
            return loadingBlock(.periodCountries)
        }, error: {
            return errorBlock(.periodCountries)
        })
            .map { AnyHashableImmuTableRow(immuTableRow: $0) }
        snapshot.appendSections([topCountriesSection])
        snapshot.appendItems(topCountriesRows, toSection: topCountriesSection)

        let topSearchTermsSection = StatsTrafficSection(periodType: .topSearchTerms)
        let topSearchTermsRows = blocks(for: .topSearchTerms,
                                        type: .period,
                                        status: store.topSearchTermsStatus,
                                        block: { [weak self] in
            return self?.searchTermsTableRows() ?? errorBlock(.periodSearchTerms)
        }, loading: {
            return loadingBlock(.periodSearchTerms)
        }, error: {
            return errorBlock(.periodSearchTerms)
        })
            .map { AnyHashableImmuTableRow(immuTableRow: $0) }
        snapshot.appendSections([topSearchTermsSection])
        snapshot.appendItems(topSearchTermsRows, toSection: topSearchTermsSection)

        let topPublishedSection = StatsTrafficSection(periodType: .topPublished)
        let topPublishedRows = blocks(for: .topPublished,
                                      type: .period,
                                      status: store.topPublishedStatus,
                                      block: { [weak self] in
            return self?.publishedTableRows() ?? errorBlock(.periodPublished)
        }, loading: {
            return loadingBlock(.periodPublished)
        }, error: {
            return errorBlock(.periodPublished)
        })
            .map { AnyHashableImmuTableRow(immuTableRow: $0) }
        snapshot.appendSections([topPublishedSection])
        snapshot.appendItems(topPublishedRows, toSection: topPublishedSection)

        let topVideosSection = StatsTrafficSection(periodType: .topVideos)
        let topVideosRows = blocks(for: .topVideos,
                                   type: .period,
                                   status: store.topVideosStatus,
                                   block: { [weak self] in
            return self?.videosTableRows() ?? errorBlock(.periodVideos)
        }, loading: {
            return loadingBlock(.periodVideos)
        }, error: {
            return errorBlock(.periodVideos)
        })
            .map { AnyHashableImmuTableRow(immuTableRow: $0) }
        snapshot.appendSections([topVideosSection])
        snapshot.appendItems(topVideosRows, toSection: topVideosSection)

        // Check for supportsFileDownloads and append if necessary
        if SiteStatsInformation.sharedInstance.supportsFileDownloads {
            let topFileDownloadsSection = StatsTrafficSection(periodType: .topFileDownloads)
            let topFileDownloadsRows = blocks(for: .topFileDownloads,
                                              type: .period,
                                              status: store.topFileDownloadsStatus,
                                              block: { [weak self] in
                return self?.fileDownloadsTableRows() ?? errorBlock(.periodFileDownloads)
            }, loading: {
                return loadingBlock(.periodFileDownloads)
            }, error: {
                return errorBlock(.periodFileDownloads)
            })
                .map { AnyHashableImmuTableRow(immuTableRow: $0) }
            snapshot.appendSections([topFileDownloadsSection])
            snapshot.appendItems(topFileDownloadsRows, toSection: topFileDownloadsSection)
        }

        return snapshot
    }

    // MARK: - Chart Date

    func entryIndex(for date: Date) -> Int {
        let endDate = { StatsPeriodHelper().endDate(from: $0, period: self.lastRequestedPeriod) }
        if let summaryData = mostRecentChartData?.summaryData {
            for (index, data) in summaryData.enumerated() {
                if endDate(data.periodStartDate) == endDate(date) {
                    return index
                }
            }
        }

        return 0
    }

    func chartDate(for entryIndex: Int) -> Date? {
        if let summaryData = mostRecentChartData?.summaryData,
            summaryData.indices.contains(entryIndex) {
            currentEntryIndex = entryIndex
            return summaryData[entryIndex].periodStartDate
        }
        return nil
    }
}

// MARK: - Private Extension

private extension SiteStatsPeriodViewModel {
    // MARK: - Create Table Rows

    func overviewTableRows() -> [any StatsHashableImmuTableRow] {
        var tableRows = [any StatsHashableImmuTableRow]()

        let periodSummary = store.getSummary()
        let summaryData = periodSummary?.summaryData ?? []

        if mostRecentChartData == nil {
            mostRecentChartData = periodSummary
        } else if let mostRecentChartData,
            let periodSummary,
            mostRecentChartData.periodEndDate == periodSummary.periodEndDate {
            self.mostRecentChartData = periodSummary
        } else if let periodSummary,   // when there is API data that has more recent API period date
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
                $0.periodStartDate.normalizedDate() <= lastRequestedDate.normalizedDate()
            })
        }

        let row = OverviewRow(
            tabsData: [viewsTabData, visitorsTabData, likesTabData, commentsTabData],
            chartData: barChartData,
            chartStyling: barChartStyling,
            period: lastRequestedPeriod,
            statsBarChartViewDelegate: statsBarChartViewDelegate,
            chartHighlightIndex: indexToHighlight,
            tabIndex: currentTabIndex
        )
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

    func referrersTableRows() -> [any StatsHashableImmuTableRow] {
        var tableRows = [any StatsHashableImmuTableRow]()
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

    func clicksTableRows() -> [any StatsHashableImmuTableRow] {
        var tableRows = [any StatsHashableImmuTableRow]()
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

    func authorsTableRows() -> [any StatsHashableImmuTableRow] {
        var tableRows = [any StatsHashableImmuTableRow]()
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodAuthors.itemSubtitle,
                                                 dataSubtitle: StatSection.periodAuthors.dataSubtitle,
                                                 dataRows: authorsDataRows(),
                                                 statSection: StatSection.periodAuthors,
                                                 siteStatsPeriodDelegate: periodDelegate))

        return tableRows
    }

    func authorsDataRows() -> [StatsTotalRowData] {
        let authors = store.getTopAuthors()?.topAuthors.prefix(10) ?? []

        return authors.map {
            StatsTotalRowData(
                name: $0.name,
                data: $0.viewsCount.abbreviatedString(),
                dataBarPercent: Float($0.viewsCount) / Float(authors.first!.viewsCount),
                userIconURL: $0.iconURL,
                showDisclosure: true,
                childRows: $0.posts.map {
                    StatsTotalRowData(
                        name: $0.title,
                        data: $0.viewsCount.abbreviatedString(),
                        postID: $0.postID,
                        showDisclosure: true,
                        disclosureURL: $0.postURL,
                        statSection: .periodAuthors
                    )
                },
                statSection: .periodAuthors
            )
        }
    }

    func countriesTableRows() -> [any StatsHashableImmuTableRow] {
        var tableRows = [any StatsHashableImmuTableRow]()
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

    func publishedTableRows() -> [any StatsHashableImmuTableRow] {
        var tableRows = [any StatsHashableImmuTableRow]()
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

    func videosTableRows() -> [any StatsHashableImmuTableRow] {
        var tableRows = [any StatsHashableImmuTableRow]()
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

    func fileDownloadsTableRows() -> [any StatsHashableImmuTableRow] {
        var tableRows = [any StatsHashableImmuTableRow]()
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodFileDownloads.itemSubtitle,
                                                 dataSubtitle: StatSection.periodFileDownloads.dataSubtitle,
                                                 dataRows: fileDownloadsDataRows(),
                                                 statSection: StatSection.periodFileDownloads,
                                                 siteStatsPeriodDelegate: periodDelegate))

        return tableRows
    }

    func fileDownloadsDataRows() -> [StatsTotalRowData] {
        return store.getTopFileDownloads()?.fileDownloads.prefix(10).map {
            StatsTotalRowData(
                id: UUID(),
                name: $0.file,
                data: $0.downloadCount.abbreviatedString(),
                statSection: .periodFileDownloads
            )
        } ?? []
    }
}

private extension SiteStatsPeriodViewModel {
    /// - Returns: `StatsPeriodUnit` granularity of period data we want to receive from API
    private func chartBarsUnit(from period: StatsPeriodUnit) -> StatsPeriodUnit {
        return period
    }

    /// - Returns: Number of bars data to fetch for a given Stats period
    private func chartBarsLimit(for period: StatsPeriodUnit) -> Int {
        return SiteStatsTableHeaderView.defaultPeriodCount
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

import Foundation
import WordPressFlux

/// The view model used by Period Stats.
///

class SiteStatsPeriodViewModel: Observable {

    // MARK: - Properties

    let changeDispatcher = Dispatcher<Void>()

    private weak var periodDelegate: SiteStatsPeriodDelegate?
    private let store: StatsPeriodStore
    private var lastRequestedPeriod: StatsPeriodUnit
    private let periodReceipt: Receipt
    private var changeReceipt: Receipt?
    private typealias Style = WPStyleGuide.Stats

    weak var statsBarChartViewDelegate: StatsBarChartViewDelegate?

    // MARK: - Constructor

    init(store: StatsPeriodStore = StoreContainer.shared.statsPeriod,
         selectedDate: Date,
         selectedPeriod: StatsPeriodUnit,
         periodDelegate: SiteStatsPeriodDelegate) {
        self.periodDelegate = periodDelegate
        self.store = store
        self.lastRequestedPeriod = selectedPeriod
        periodReceipt = store.query(.periods(date: selectedDate, period: selectedPeriod))
        store.actionDispatcher.dispatch(PeriodAction.refreshPeriodOverviewData(date: selectedDate, period: selectedPeriod, forceRefresh: false))

        changeReceipt = store.onChange { [weak self] in
            self?.emitChange()
        }
    }

    // MARK: - Table Model

    func tableViewModel() -> ImmuTable {

        var tableRows = [ImmuTableRow]()

        tableRows.append(contentsOf: overviewTableRows())
        tableRows.append(contentsOf: postsAndPagesTableRows())
        tableRows.append(contentsOf: referrersTableRows())
        tableRows.append(contentsOf: clicksTableRows())
        tableRows.append(contentsOf: authorsTableRows())
        tableRows.append(contentsOf: countriesTableRows())
        tableRows.append(contentsOf: searchTermsTableRows())
        tableRows.append(contentsOf: publishedTableRows())
        tableRows.append(contentsOf: videosTableRows())
        tableRows.append(TableFooterRow())

        return ImmuTable(sections: [
            ImmuTableSection(
                rows: tableRows)
            ])
    }

    // MARK: - Refresh Data

    func refreshPeriodOverviewData(withDate date: Date, forPeriod period: StatsPeriodUnit) {
        ActionDispatcher.dispatch(PeriodAction.refreshPeriodOverviewData(date: date, period: period, forceRefresh: true))
        self.lastRequestedPeriod = period
    }
}

// MARK: - Private Extension

private extension SiteStatsPeriodViewModel {

    // MARK: - Create Table Rows

    func overviewTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(CellHeaderRow(title: ""))

        let summaryData = store.getSummary()?.summaryData ?? []

        let viewsData = intervalData(summaryData: summaryData, summaryType: .views)
        let viewsTabData = OverviewTabData(tabTitle: StatSection.periodOverviewViews.tabTitle,
                                           tabData: viewsData.count,
                                           difference: viewsData.difference,
                                           differencePercent: viewsData.percentage)

        let visitorsData = intervalData(summaryData: summaryData, summaryType: .visitors)
        let visitorsTabData = OverviewTabData(tabTitle: StatSection.periodOverviewVisitors.tabTitle,
                                              tabData: visitorsData.count,
                                              difference: visitorsData.difference,
                                              differencePercent: visitorsData.percentage)

        let likesData = intervalData(summaryData: summaryData, summaryType: .likes)
        let likesTabData = OverviewTabData(tabTitle: StatSection.periodOverviewLikes.tabTitle,
                                           tabData: likesData.count,
                                           difference: likesData.difference,
                                           differencePercent: likesData.percentage)

        let commentsData = intervalData(summaryData: summaryData, summaryType: .comments)
        let commentsTabData = OverviewTabData(tabTitle: StatSection.periodOverviewComments.tabTitle,
                                              tabData: commentsData.count,
                                              difference: commentsData.difference,
                                              differencePercent: commentsData.percentage)

        var barChartData = [BarChartDataConvertible]()
        var barChartStyling = [BarChartStyling]()
        if let chartData = store.getSummary() {
            let chart = PeriodChart(data: chartData, period: lastRequestedPeriod)

            barChartData.append(contentsOf: chart.barChartData)
            barChartStyling.append(contentsOf: chart.barChartStyling)
        }

        let row = OverviewRow(tabsData: [viewsTabData, visitorsTabData, likesTabData, commentsTabData],
                              chartData: barChartData, chartStyling: barChartStyling, period: lastRequestedPeriod, statsBarChartViewDelegate: statsBarChartViewDelegate)
        tableRows.append(row)

        return tableRows
    }

    func intervalData(summaryData: [StatsSummaryData],
                      summaryType: StatsSummaryType) ->
        (count: Int, difference: Int, percentage: Int) {

        guard let currentInterval = summaryData.last else {
            return (0, 0, 0)
        }

        let previousInterval = summaryData.count >= 2 ? summaryData[summaryData.count-2] : nil

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
        tableRows.append(CellHeaderRow(title: StatSection.periodPostsAndPages.title))
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
                icon = Style.imageForGridiconType(.house)
            case .page:
                icon = Style.imageForGridiconType(.pages)
            case .post:
                icon = Style.imageForGridiconType(.posts)
            case .unknown:
                icon = Style.imageForGridiconType(.posts)
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
        tableRows.append(CellHeaderRow(title: StatSection.periodReferrers.title))
        tableRows.append(TopTotalsPeriodStatsRow(itemSubtitle: StatSection.periodReferrers.itemSubtitle,
                                                 dataSubtitle: StatSection.periodReferrers.dataSubtitle,
                                                 dataRows: referrersDataRows(),
                                                 siteStatsPeriodDelegate: periodDelegate))

        return tableRows
    }

    func referrersDataRows() -> [StatsTotalRowData] {
        let referrers = store.getTopReferrers()?.referrers.prefix(10) ?? []

        func rowDataFromReferrer(referrer: StatsReferrer) -> StatsTotalRowData {
            return StatsTotalRowData(name: referrer.title,
                                     data: referrer.viewsCount.abbreviatedString(),
                                     socialIconURL: referrer.iconURL,
                                     showDisclosure: true,
                                     disclosureURL: referrer.url,
                                     childRows: referrer.children.map { rowDataFromReferrer(referrer: $0) },
                                     statSection: .periodReferrers)
        }

        return referrers.map { rowDataFromReferrer(referrer: $0) }
    }

    func clicksTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(CellHeaderRow(title: StatSection.periodClicks.title))
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
        tableRows.append(CellHeaderRow(title: StatSection.periodAuthors.title))
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
        tableRows.append(CellHeaderRow(title: StatSection.periodCountries.title))
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

    func searchTermsTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(CellHeaderRow(title: StatSection.periodSearchTerms.title))
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
        tableRows.append(CellHeaderRow(title: StatSection.periodPublished.title))
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
        tableRows.append(CellHeaderRow(title: StatSection.periodVideos.title))
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

}

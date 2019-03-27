import Foundation
import WordPressFlux

/// The view model used by Period Stats.
///

class SiteStatsPeriodViewModel: Observable {

    // MARK: - Properties

    let changeDispatcher = Dispatcher<Void>()

    private let periodDelegate: SiteStatsPeriodDelegate
    private let store: StatsPeriodStore
    private let periodReceipt: Receipt
    private var changeReceipt: Receipt?
    private typealias Style = WPStyleGuide.Stats

    // MARK: - Constructor

    init(store: StatsPeriodStore = StoreContainer.shared.statsPeriod,
         selectedDate: Date,
         selectedPeriod: StatsPeriodUnit,
         periodDelegate: SiteStatsPeriodDelegate) {
        self.periodDelegate = periodDelegate
        self.store = store
        periodReceipt = store.query(.periods(date: selectedDate, period: selectedPeriod))

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
        ActionDispatcher.dispatch(PeriodAction.refreshPeriodOverviewData(date: date, period: period))
    }
}

// MARK: - Private Extension

private extension SiteStatsPeriodViewModel {

    // MARK: - Create Table Rows

    func overviewTableRows() -> [ImmuTableRow] {
        var tableRows = [ImmuTableRow]()
        tableRows.append(CellHeaderRow(title: ""))

        // TODO: replace with real data
        let one = OverviewTabData(tabTitle: StatSection.periodOverviewViews.tabTitle, tabData: 85296, difference: -987, differencePercent: 5)
        let two = OverviewTabData(tabTitle: StatSection.periodOverviewVisitors.tabTitle, tabData: 741, difference: 22222, differencePercent: 50)
        let three = OverviewTabData(tabTitle: StatSection.periodOverviewLikes.tabTitle, tabData: 12345, difference: 75324, differencePercent: 27)
        let four = OverviewTabData(tabTitle: StatSection.periodOverviewComments.tabTitle, tabData: 987654321, difference: -258547987, differencePercent: -125999)

        // Introduced via #11063, to be replaced with real data via #11069
        let stubbedData = PeriodDataStub()
        let firstStubbedDateInterval = stubbedData.periodData.first?.date.timeIntervalSince1970 ?? 0
        let styling = PeriodPerformanceStyling(initialDateInterval: firstStubbedDateInterval)

        let row = OverviewRow(tabsData: [one, two, three, four], chartData: stubbedData, chartStyling: styling)
        tableRows.append(row)

        return tableRows
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
        let postsAndPages = store.getTopPostsAndPages()?.topPosts ?? []

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
        let referrers = store.getTopReferrers()?.referrers ?? []

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
        return store.getTopClicks()?.clicks.map { StatsTotalRowData(name: $0.title,
                                                                    data: $0.clicksCount.abbreviatedString(),
                                                                    userIconURL: $0.iconURL,
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
        let authors = store.getTopAuthors()?.topAuthors ?? []


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
        return store.getTopCountries()?.countries.map { StatsTotalRowData(name: $0.name,
                                                                          data: $0.viewsCount.abbreviatedString(),
                                                                          countryIconURL: nil, // TODO Move this from WPStatsiOS.
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

        var mappedSearchTerms = searchTerms.searchTerms.map { StatsTotalRowData(name: $0.term,
                                                                                data: $0.viewsCount.abbreviatedString(),
                                                                                statSection: .periodSearchTerms) }

        let unknownSearchTerm = StatsTotalRowData(name: NSLocalizedString("Unknown search terms",
                                                                          comment: "Search Terms label for 'unknown search terms'."),
                                                  data: searchTerms.hiddenSearchTermsCount.abbreviatedString(),
                                                  statSection: .periodSearchTerms)

        mappedSearchTerms.insert(unknownSearchTerm, at: 0)

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
        return store.getTopPublished()?.publishedPosts.map { StatsTotalRowData.init(name: $0.title,
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
        return store.getTopVideos()?.videos.map { StatsTotalRowData(name: $0.title,
                                                                    data: $0.playsCount.abbreviatedString(),
                                                                    mediaID: 0, //TODO Currently backend only returns URLs, not IDs.
                                                                    icon: Style.imageForGridiconType(.video),
                                                                    showDisclosure: true,
                                                                    statSection: .periodVideos) }
            ?? []
    }

}

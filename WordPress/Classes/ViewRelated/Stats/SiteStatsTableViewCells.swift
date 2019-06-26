import UIKit

// MARK: - Shared Rows

struct OverviewRow: ImmuTableRow {

    typealias CellType = OverviewCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let tabsData: [OverviewTabData]
    let action: ImmuTableAction? = nil
    let chartData: [BarChartDataConvertible]
    let chartStyling: [BarChartStyling]
    let period: StatsPeriodUnit?
    weak var statsBarChartViewDelegate: StatsBarChartViewDelegate?
    let chartHighlightIndex: Int?

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(tabsData: tabsData, barChartData: chartData, barChartStyling: chartStyling, period: period, statsBarChartViewDelegate: statsBarChartViewDelegate, barChartHighlightIndex: chartHighlightIndex)
    }
}

struct CellHeaderRow: ImmuTableRow {

    typealias CellType = StatsCellHeader

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let title: String
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(withTitle: title)
    }
}

struct TableFooterRow: ImmuTableRow {

    typealias CellType = StatsTableFooter

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {
        // No configuration needed.
        // This method is needed to satisfy ImmuTableRow protocol requirements.
    }
}

// MARK: - Insights Rows

struct LatestPostSummaryRow: ImmuTableRow {

    typealias CellType = LatestPostSummaryCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let summaryData: StatsLastPostInsight?
    let chartData: StatsPostDetails?
    weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(withInsightData: summaryData, chartData: chartData, andDelegate: siteStatsInsightsDelegate)

    }
}

struct PostingActivityRow: ImmuTableRow {

    typealias CellType = PostingActivityCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let monthsData: [[PostingStreakEvent]]
    weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(withData: monthsData, andDelegate: siteStatsInsightsDelegate)
    }
}

struct TabbedTotalsStatsRow: ImmuTableRow {

    typealias CellType = TabbedTotalsCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let tabsData: [TabData]
    weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    let showTotalCount: Bool
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(tabsData: tabsData,
                       siteStatsInsightsDelegate: siteStatsInsightsDelegate,
                       showTotalCount: showTotalCount)
    }
}

struct TopTotalsInsightStatsRow: ImmuTableRow {

    typealias CellType = TopTotalsCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let itemSubtitle: String
    let dataSubtitle: String
    let dataRows: [StatsTotalRowData]
    weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        let limitRowsDisplayed = !(dataRows.first?.statSection == .insightsPublicize)

        cell.configure(itemSubtitle: itemSubtitle,
                       dataSubtitle: dataSubtitle,
                       dataRows: dataRows,
                       siteStatsInsightsDelegate: siteStatsInsightsDelegate,
                       limitRowsDisplayed: limitRowsDisplayed)
    }
}

struct TwoColumnStatsRow: ImmuTableRow {

    typealias CellType = TwoColumnCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let dataRows: [StatsTwoColumnRowData]
    let statSection: StatSection
    weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(dataRows: dataRows, statSection: statSection, siteStatsInsightsDelegate: siteStatsInsightsDelegate)
    }
}

// MARK: - Period Rows

struct TopTotalsPeriodStatsRow: ImmuTableRow {

    typealias CellType = TopTotalsCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let itemSubtitle: String
    let dataSubtitle: String
    let dataRows: [StatsTotalRowData]
    weak var siteStatsPeriodDelegate: SiteStatsPeriodDelegate?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(itemSubtitle: itemSubtitle,
                       dataSubtitle: dataSubtitle,
                       dataRows: dataRows,
                       siteStatsPeriodDelegate: siteStatsPeriodDelegate)
    }
}

struct TopTotalsNoSubtitlesPeriodStatsRow: ImmuTableRow {

    typealias CellType = TopTotalsCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let dataRows: [StatsTotalRowData]
    weak var siteStatsPeriodDelegate: SiteStatsPeriodDelegate?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(dataRows: dataRows, siteStatsPeriodDelegate: siteStatsPeriodDelegate)
    }
}

struct CountriesStatsRow: ImmuTableRow {

    typealias CellType = CountriesCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let itemSubtitle: String
    let dataSubtitle: String
    let dataRows: [StatsTotalRowData]
    weak var siteStatsPeriodDelegate: SiteStatsPeriodDelegate?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(itemSubtitle: itemSubtitle,
                       dataSubtitle: dataSubtitle,
                       dataRows: dataRows,
                       siteStatsPeriodDelegate: siteStatsPeriodDelegate)
    }
}

struct CountriesMapRow: ImmuTableRow {
    let action: ImmuTableAction? = nil
    let countriesMap: CountriesMap

    typealias CellType = CountriesMapCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? CellType else {
            return
        }
        cell.configure(with: countriesMap)
    }
}

// MARK: - Post Stats Rows

struct PostStatsTitleRow: ImmuTableRow {

    typealias CellType = PostStatsTitleCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let postTitle: String
    let postURL: URL?
    weak var postStatsDelegate: PostStatsDelegate?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(postTitle: postTitle, postURL: postURL, postStatsDelegate: postStatsDelegate)
    }
}

struct TopTotalsPostStatsRow: ImmuTableRow {

    typealias CellType = TopTotalsCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let itemSubtitle: String
    let dataSubtitle: String
    let dataRows: [StatsTotalRowData]
    let limitRowsDisplayed: Bool
    weak var postStatsDelegate: PostStatsDelegate?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(itemSubtitle: itemSubtitle,
                       dataSubtitle: dataSubtitle,
                       dataRows: dataRows,
                       postStatsDelegate: postStatsDelegate,
                       limitRowsDisplayed: limitRowsDisplayed)
    }
}

struct PostStatsEmptyCellHeaderRow: ImmuTableRow {

    typealias CellType = StatsCellHeader

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(withTitle: "", adjustHeightForPostStats: true)
    }
}

// MARK: - Detail Rows

struct DetailDataRow: ImmuTableRow {

    typealias CellType = DetailDataCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let rowData: StatsTotalRowData
    weak var detailsDelegate: SiteStatsDetailsDelegate?
    let hideIndentedSeparator: Bool
    let hideFullSeparator: Bool
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(rowData: rowData,
                       detailsDelegate: detailsDelegate,
                       hideIndentedSeparator: hideIndentedSeparator,
                       hideFullSeparator: hideFullSeparator)
    }
}

struct DetailExpandableRow: ImmuTableRow {

    typealias CellType = DetailDataCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let rowData: StatsTotalRowData
    weak var detailsDelegate: SiteStatsDetailsDelegate?
    let hideIndentedSeparator: Bool
    let hideFullSeparator: Bool
    let expanded: Bool
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(rowData: rowData,
                       detailsDelegate: detailsDelegate,
                       hideIndentedSeparator: hideIndentedSeparator,
                       hideFullSeparator: hideFullSeparator,
                       expanded: expanded)

    }
}

struct DetailExpandableChildRow: ImmuTableRow {

    typealias CellType = DetailDataCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let rowData: StatsTotalRowData
    weak var detailsDelegate: SiteStatsDetailsDelegate?
    let hideIndentedSeparator: Bool
    let hideFullSeparator: Bool
    let showImage: Bool
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(rowData: rowData,
                       detailsDelegate: detailsDelegate,
                       hideIndentedSeparator: hideIndentedSeparator,
                       hideFullSeparator: hideFullSeparator,
                       isChildRow: true,
                       showChildRowImage: showImage)
    }
}

struct DetailSubtitlesHeaderRow: ImmuTableRow {

    typealias CellType = TopTotalsCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let itemSubtitle: String
    let dataSubtitle: String
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(itemSubtitle: itemSubtitle, dataSubtitle: dataSubtitle, dataRows: [], forDetails: true)
    }
}

struct DetailSubtitlesCountriesHeaderRow: ImmuTableRow {

    typealias CellType = CountriesCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let itemSubtitle: String
    let dataSubtitle: String
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(itemSubtitle: itemSubtitle, dataSubtitle: dataSubtitle, dataRows: [], forDetails: true)
    }
}

struct DetailSubtitlesTabbedHeaderRow: ImmuTableRow {

    typealias CellType = TabbedTotalsCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let tabsData: [TabData]
    weak var siteStatsDetailsDelegate: SiteStatsDetailsDelegate?
    let showTotalCount: Bool
    let selectedIndex: Int
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(tabsData: tabsData,
                       siteStatsDetailsDelegate: siteStatsDetailsDelegate,
                       showTotalCount: showTotalCount,
                       selectedIndex: selectedIndex,
                       forDetails: true)
    }
}

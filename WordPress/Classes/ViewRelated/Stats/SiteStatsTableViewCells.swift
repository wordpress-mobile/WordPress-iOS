import UIKit
import Gridicons

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

struct ViewsVisitorsRow: ImmuTableRow {

    typealias CellType = ViewsVisitorsLineChartCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let segmentsData: [StatsSegmentedControlData]
    let selectedSegment: StatsSegmentedControlData.Segment
    let action: ImmuTableAction? = nil
    let chartData: [LineChartDataConvertible]
    let chartStyling: [LineChartStyling]
    let period: StatsPeriodUnit?
    weak var statsLineChartViewDelegate: StatsLineChartViewDelegate?
    weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    weak var viewsAndVisitorsDelegate: StatsInsightsViewsAndVisitorsDelegate?
    let xAxisDates: [Date]

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(row: self)
    }
}

struct CellHeaderRow: ImmuTableRow {

    typealias CellType = StatsCellHeader

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let statSection: StatSection
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(statSection: statSection)
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

struct InsightCellHeaderRow: ImmuTableRow {

    typealias CellType = StatsCellHeader

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let statSection: StatSection
    weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(statSection: statSection, siteStatsInsightsDelegate: siteStatsInsightsDelegate)
    }
}

struct GrowAudienceRow: ImmuTableRow {

    typealias CellType = GrowAudienceCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let hintType: GrowAudienceCell.HintType
    let allTimeViewsCount: Int
    let isNudgeCompleted: Bool
    weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(hintType: hintType,
                       allTimeViewsCount: allTimeViewsCount,
                       isNudgeCompleted: isNudgeCompleted,
                       insightsDelegate: siteStatsInsightsDelegate)
    }
}

struct CustomizeInsightsRow: ImmuTableRow {

    typealias CellType = CustomizeInsightsCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(insightsDelegate: siteStatsInsightsDelegate)
    }

}

struct LatestPostSummaryRow: ImmuTableRow {

    static var cell: ImmuTableCell {
        if AppConfiguration.statsRevampV2Enabled {
            return ImmuTableCell.class(StatsLatestPostSummaryInsightsCell.self)
        } else {
            return ImmuTableCell.nib(LatestPostSummaryCell.defaultNib, LatestPostSummaryCell.self)
        }
    }

    let summaryData: StatsLastPostInsight?
    let chartData: StatsPostDetails?
    weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? LatestPostSummaryConfigurable else {
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
    let statSection: StatSection
    weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    weak var siteStatsDetailsDelegate: SiteStatsDetailsDelegate?
    let showTotalCount: Bool
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(tabsData: tabsData,
                       statSection: statSection,
                       siteStatsInsightsDelegate: siteStatsInsightsDelegate,
                       siteStatsDetailsDelegate: siteStatsDetailsDelegate,
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
    let statSection: StatSection
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
                       statSection: statSection,
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

struct MostPopularTimeInsightStatsRow: ImmuTableRow {

    typealias CellType = StatsMostPopularTimeInsightsCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.class(CellType.self)
    }()

    let data: StatsMostPopularTimeData?
    weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(data: data, siteStatsInsightsDelegate: siteStatsInsightsDelegate)
    }
}

struct TotalInsightStatsRow: ImmuTableRow {

    typealias CellType = StatsTotalInsightsCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.class(CellType.self)
    }()

    let dataRow: StatsTotalInsightsData
    let statSection: StatSection
    weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(dataRow: dataRow, statSection: statSection, siteStatsInsightsDelegate: siteStatsInsightsDelegate)
    }
}

// MARK: - Insights Management

struct AddInsightRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellDefault.self)

    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = StatSection.insightsAddInsight.title
        cell.accessoryView = UIImageView(image: WPStyleGuide.Stats.imageForGridiconType(.plus, withTint: .darkGrey))
        cell.accessibilityTraits = .button
        cell.accessibilityLabel = StatSection.insightsAddInsight.title
        cell.accessibilityHint = NSLocalizedString("Tap to add new stats cards.", comment: "Accessibility hint for a button that opens a view that allows to add new stats cards.")
    }
}

struct AddInsightStatRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellDefault.self)

    let title: String
    let enabled: Bool
    let action: ImmuTableAction?

    let enabledHint = NSLocalizedString("Select to add this stat to Insights.", comment: "Accessibility hint for stat available to add to Insights.")
    let disabledHint = NSLocalizedString("Stat is already displayed in Insights.", comment: "Accessibility hint for stat not available to add to Insights.")

    func configureCell(_ cell: UITableViewCell) {
        WPStyleGuide.configureTableViewCell(cell)

        cell.textLabel?.text = title
        cell.textLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.textColor = AppConfiguration.statsRevampV2Enabled || enabled ? .text : .textPlaceholder
        cell.selectionStyle = .none

        cell.accessibilityLabel = title
        cell.isAccessibilityElement = true

        let canTap = AppConfiguration.statsRevampV2Enabled ? action != nil : enabled
        cell.accessibilityTraits = canTap ? .button : .notEnabled
        cell.accessibilityHint = canTap && enabled ? disabledHint : enabledHint

        if AppConfiguration.statsRevampV2Enabled {
            cell.accessoryView = canTap ? UIImageView(image: UIImage(systemName: Constants.plusIconName)) : nil

            let editingImageView = UIImageView(image: UIImage(systemName: Constants.minusIconName))
            editingImageView.tintColor = .textSubtle
            cell.editingAccessoryView = editingImageView
        }
    }

    private enum Constants {
        static let plusIconName = "plus.circle"
        static let minusIconName = "minus.circle"
    }
}

// MARK: - Period Rows

struct PeriodEmptyCellHeaderRow: ImmuTableRow {

    typealias CellType = StatsCellHeader

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure()
    }
}

struct TopTotalsPeriodStatsRow: ImmuTableRow {

    typealias CellType = TopTotalsCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let itemSubtitle: String
    let dataSubtitle: String
    let dataRows: [StatsTotalRowData]
    var statSection: StatSection?
    weak var siteStatsPeriodDelegate: SiteStatsPeriodDelegate?
    weak var siteStatsReferrerDelegate: SiteStatsReferrerDelegate?
    weak var siteStatsInsightsDetailsDelegate: SiteStatsInsightsDelegate?
    weak var siteStatsDetailsDelegate: SiteStatsDetailsDelegate?
    var topAccessoryView: UIView? = nil
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(itemSubtitle: itemSubtitle,
                       dataSubtitle: dataSubtitle,
                       dataRows: dataRows,
                       statSection: statSection,
                       siteStatsInsightsDelegate: siteStatsInsightsDetailsDelegate,
                       siteStatsPeriodDelegate: siteStatsPeriodDelegate,
                       siteStatsReferrerDelegate: siteStatsReferrerDelegate,
                       siteStatsDetailsDelegate: siteStatsDetailsDelegate,
                       topAccessoryView: topAccessoryView)
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
    var statSection: StatSection?
    let dataRows: [StatsTotalRowData]
    weak var siteStatsPeriodDelegate: SiteStatsPeriodDelegate?
    weak var siteStatsInsightsDetailsDelegate: SiteStatsInsightsDelegate?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(itemSubtitle: itemSubtitle,
                       dataSubtitle: dataSubtitle,
                       dataRows: dataRows,
                       siteStatsPeriodDelegate: siteStatsPeriodDelegate,
                       siteStatsInsightsDetailsDelegate: siteStatsInsightsDetailsDelegate)
        cell.statSection = statSection
    }
}

struct CountriesMapRow: ImmuTableRow {
    let action: ImmuTableAction? = nil
    let countriesMap: CountriesMap
    var statSection: StatSection?

    typealias CellType = CountriesMapCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? CellType else {
            return
        }
        cell.configure(with: countriesMap)
        cell.statSection = statSection
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

        cell.configure(statSection: .postStatsGraph)
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
    weak var referrerDelegate: SiteStatsReferrerDelegate?
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
                       referrerDelegate: referrerDelegate,
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

struct StatsErrorRow: ImmuTableRow {
    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(StatsStackViewCell.defaultNib, StatsStackViewCell.self)
    }()
    let action: ImmuTableAction? = nil
    let rowStatus: StoreFetchingStatus
    let statType: StatType
    let statSection: StatSection?

    private let noDataRow = StatsNoDataRow.loadFromNib()

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? StatsStackViewCell else {
            return
        }

        noDataRow.configure(forType: statType, rowStatus: rowStatus)
        cell.insert(view: noDataRow)

        if let statSection = statSection {
           cell.statSection = statSection
        }
    }
}

import UIKit
import Gridicons
import DGCharts

// MARK: - Shared Rows

// TODO: Remove with SiteStatsPeriodViewModelDeprecated
struct OverviewRow: ImmuTableRow {

    typealias CellType = OverviewCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let tabsData: [OverviewTabData]
    let action: ImmuTableAction? = nil
    let chartData: [any BarChartDataConvertible]
    let chartStyling: [BarChartStyling]
    let period: StatsPeriodUnit?
    weak var statsBarChartViewDelegate: StatsBarChartViewDelegate?
    let chartHighlightIndex: Int?
    let statSection: StatSection? = nil

    // MARK: - Hashable

    static func == (lhs: OverviewRow, rhs: OverviewRow) -> Bool {
        return lhs.tabsData == rhs.tabsData &&
            lhs.chartHighlightIndex == rhs.chartHighlightIndex
    }

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(tabsData: tabsData, barChartData: chartData, barChartStyling: chartStyling, period: period, statsBarChartViewDelegate: statsBarChartViewDelegate, barChartHighlightIndex: chartHighlightIndex)
    }
}
struct StatsTrafficBarChartRow: StatsHashableImmuTableRow {
    typealias CellType = StatsTrafficBarChartCell
    let action: ImmuTableAction?
    let tabsData: [StatsTrafficBarChartTabData]
    let chartData: [BarChartDataConvertible]
    let chartStyling: [StatsTrafficBarChartStyling]
    let statSection: StatSection? = nil
    let period: StatsPeriodUnit
    let unit: StatsPeriodUnit

    static let cell: ImmuTableCell = {
        return ImmuTableCell.class(CellType.self)
    }()

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else { return }

        cell.configure(tabsData: tabsData, barChartData: chartData, barChartStyling: chartStyling, period: period, unit: unit)
    }

    static func == (lhs: StatsTrafficBarChartRow, rhs: StatsTrafficBarChartRow) -> Bool {
        return lhs.tabsData == rhs.tabsData && lhs.period == rhs.period && lhs.unit == rhs.unit
    }
}

struct ViewsVisitorsRow: StatsHashableImmuTableRow {
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
    let statSection: StatSection?

    static func == (lhs: ViewsVisitorsRow, rhs: ViewsVisitorsRow) -> Bool {
        return lhs.segmentsData == rhs.segmentsData &&
            lhs.selectedSegment == rhs.selectedSegment &&
            lhs.xAxisDates == rhs.xAxisDates &&
            lhs.period == rhs.period
    }

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(row: self)
    }
}

struct CellHeaderRow: StatsHashableImmuTableRow {

    typealias CellType = StatsCellHeader

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let statSection: StatSection?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(statSection: statSection)
    }

    // MARK: - Hashable

    static func == (lhs: CellHeaderRow, rhs: CellHeaderRow) -> Bool {
        return lhs.statSection == rhs.statSection
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

struct GrowAudienceRow: StatsHashableImmuTableRow {
    typealias CellType = GrowAudienceCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let hintType: GrowAudienceCell.HintType
    let allTimeViewsCount: Int
    let isNudgeCompleted: Bool
    weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    let action: ImmuTableAction? = nil
    let statSection: StatSection?

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(hintType: hintType,
                       allTimeViewsCount: allTimeViewsCount,
                       isNudgeCompleted: isNudgeCompleted,
                       insightsDelegate: siteStatsInsightsDelegate)
    }

    static func == (lhs: GrowAudienceRow, rhs: GrowAudienceRow) -> Bool {
        return lhs.hintType == rhs.hintType &&
            lhs.allTimeViewsCount == rhs.allTimeViewsCount &&
            lhs.isNudgeCompleted == rhs.isNudgeCompleted
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

struct LatestPostSummaryRow: StatsHashableImmuTableRow {
    static var cell: ImmuTableCell {
        return ImmuTableCell.class(StatsLatestPostSummaryInsightsCell.self)
    }

    let summaryData: StatsLastPostInsight?
    let chartData: StatsPostDetails?
    weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    let action: ImmuTableAction? = nil
    let statSection: StatSection?

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? LatestPostSummaryConfigurable else {
            return
        }

        cell.configure(withInsightData: summaryData, chartData: chartData, andDelegate: siteStatsInsightsDelegate)
    }

    static func == (lhs: LatestPostSummaryRow, rhs: LatestPostSummaryRow) -> Bool {
        return lhs.summaryData == rhs.summaryData && lhs.chartData == rhs.chartData
    }
}

struct PostingActivityRow: StatsHashableImmuTableRow {
    typealias CellType = PostingActivityCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let monthsData: [[PostingStreakEvent]]
    weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    let action: ImmuTableAction? = nil
    let statSection: StatSection?

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(withData: monthsData, andDelegate: siteStatsInsightsDelegate)
    }

    static func == (lhs: PostingActivityRow, rhs: PostingActivityRow) -> Bool {
        return lhs.monthsData == rhs.monthsData
    }
}

struct TabbedTotalsStatsRow: StatsHashableImmuTableRow {
    typealias CellType = TabbedTotalsCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let tabsData: [TabData]
    let statSection: StatSection?
    weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    weak var siteStatsDetailsDelegate: SiteStatsDetailsDelegate?
    let showTotalCount: Bool
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType, let statSection else {
            return
        }

        cell.configure(tabsData: tabsData,
                       statSection: statSection,
                       siteStatsInsightsDelegate: siteStatsInsightsDelegate,
                       siteStatsDetailsDelegate: siteStatsDetailsDelegate,
                       showTotalCount: showTotalCount)
    }

    static func == (lhs: TabbedTotalsStatsRow, rhs: TabbedTotalsStatsRow) -> Bool {
        return lhs.tabsData == rhs.tabsData &&
            lhs.statSection == rhs.statSection &&
            lhs.showTotalCount == rhs.showTotalCount
    }
}

struct TopTotalsInsightStatsRow: StatsHashableImmuTableRow {

    typealias CellType = TopTotalsCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let itemSubtitle: String
    let dataSubtitle: String
    let dataRows: [StatsTotalRowData]
    let statSection: StatSection?
    weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType, let statSection else {
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

    static func == (lhs: TopTotalsInsightStatsRow, rhs: TopTotalsInsightStatsRow) -> Bool {
        return lhs.itemSubtitle == rhs.itemSubtitle &&
            lhs.dataSubtitle == rhs.dataSubtitle &&
            lhs.dataRows == rhs.dataRows &&
            lhs.statSection == rhs.statSection
    }
}

struct TwoColumnStatsRow: StatsHashableImmuTableRow {
    typealias CellType = TwoColumnCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let dataRows: [StatsTwoColumnRowData]
    let statSection: StatSection?
    weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? CellType, let statSection else {
            return
        }

        cell.configure(dataRows: dataRows, statSection: statSection, siteStatsInsightsDelegate: siteStatsInsightsDelegate)
    }

    static func == (lhs: TwoColumnStatsRow, rhs: TwoColumnStatsRow) -> Bool {
        return lhs.dataRows == rhs.dataRows && lhs.statSection == rhs.statSection
    }
}

struct MostPopularTimeInsightStatsRow: StatsHashableImmuTableRow {
    typealias CellType = StatsMostPopularTimeInsightsCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.class(CellType.self)
    }()

    let data: StatsMostPopularTimeData?
    weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    let action: ImmuTableAction? = nil
    let statSection: StatSection?

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(data: data, siteStatsInsightsDelegate: siteStatsInsightsDelegate)
    }

    static func == (lhs: MostPopularTimeInsightStatsRow, rhs: MostPopularTimeInsightStatsRow) -> Bool {
        return lhs.data == rhs.data
    }
}

struct TotalInsightStatsRow: StatsHashableImmuTableRow {
    typealias CellType = StatsTotalInsightsCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.class(CellType.self)
    }()

    let dataRow: StatsTotalInsightsData
    let statSection: StatSection?
    weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? CellType, let statSection else {
            return
        }

        cell.configure(dataRow: dataRow, statSection: statSection, siteStatsInsightsDelegate: siteStatsInsightsDelegate)
    }

    static func == (lhs: TotalInsightStatsRow, rhs: TotalInsightStatsRow) -> Bool {
        return lhs.dataRow == rhs.dataRow && lhs.statSection == rhs.statSection
    }
}

// MARK: - Insights Management

struct AddInsightRow: StatsHashableImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellDefault.self)

    let action: ImmuTableAction?
    let statSection: StatSection?

    func configureCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = StatSection.insightsAddInsight.title
        cell.accessoryView = UIImageView(image: WPStyleGuide.Stats.imageForGridiconType(.plus, withTint: .darkGrey))
        cell.accessibilityTraits = .button
        cell.accessibilityLabel = StatSection.insightsAddInsight.title
        cell.accessibilityHint = NSLocalizedString("Tap to add new stats cards.", comment: "Accessibility hint for a button that opens a view that allows to add new stats cards.")
    }

    static func == (lhs: AddInsightRow, rhs: AddInsightRow) -> Bool {
        return lhs.statSection == rhs.statSection
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
        cell.textLabel?.textColor = enabled ? .text : .textPlaceholder
        cell.selectionStyle = .none

        cell.accessibilityLabel = title
        cell.isAccessibilityElement = true

        let canTap = action != nil
        cell.accessibilityTraits = canTap ? .button : .notEnabled
        cell.accessibilityHint = canTap && enabled ? disabledHint : enabledHint
        cell.accessoryView = canTap ? UIImageView(image: UIImage(systemName: Constants.plusIconName)) : nil

        let editingImageView = UIImageView(image: UIImage(systemName: Constants.minusIconName))
        editingImageView.tintColor = .textSubtle
        cell.editingAccessoryView = editingImageView
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

struct TopTotalsPeriodStatsRow: StatsHashableImmuTableRow {

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

    // MARK: - Hashable

    static func == (lhs: TopTotalsPeriodStatsRow, rhs: TopTotalsPeriodStatsRow) -> Bool {
        return lhs.itemSubtitle == rhs.itemSubtitle &&
            lhs.dataSubtitle == rhs.dataSubtitle &&
            lhs.dataRows == rhs.dataRows &&
            lhs.statSection == rhs.statSection
    }

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

struct TopTotalsNoSubtitlesPeriodStatsRow: StatsHashableImmuTableRow {

    typealias CellType = TopTotalsCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    let dataRows: [StatsTotalRowData]
    var statSection: StatSection? = nil
    weak var siteStatsPeriodDelegate: SiteStatsPeriodDelegate?
    let action: ImmuTableAction? = nil

    // MARK: - Hashable

    static func == (lhs: TopTotalsNoSubtitlesPeriodStatsRow, rhs: TopTotalsNoSubtitlesPeriodStatsRow) -> Bool {
        return lhs.dataRows == rhs.dataRows &&
            lhs.statSection == rhs.statSection
    }

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.configure(dataRows: dataRows, statSection: statSection, siteStatsPeriodDelegate: siteStatsPeriodDelegate)
    }
}

struct CountriesStatsRow: StatsHashableImmuTableRow {

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

    // MARK: - Hashable

    static func == (lhs: CountriesStatsRow, rhs: CountriesStatsRow) -> Bool {
        return lhs.itemSubtitle == rhs.itemSubtitle &&
            lhs.dataSubtitle == rhs.dataSubtitle &&
            lhs.statSection == rhs.statSection &&
            lhs.dataRows == rhs.dataRows
    }

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

struct CountriesMapRow: StatsHashableImmuTableRow {
    let action: ImmuTableAction? = nil
    let countriesMap: CountriesMap
    var statSection: StatSection?

    typealias CellType = CountriesMapCell

    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(CellType.defaultNib, CellType.self)
    }()

    // MARK: - Hashable

    static func == (lhs: CountriesMapRow, rhs: CountriesMapRow) -> Bool {
        return lhs.countriesMap == rhs.countriesMap &&
            lhs.statSection == rhs.statSection
    }

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

struct StatsErrorRow: StatsHashableImmuTableRow {
    static let cell: ImmuTableCell = {
        return ImmuTableCell.nib(StatsStackViewCell.defaultNib, StatsStackViewCell.self)
    }()
    let action: ImmuTableAction? = nil
    let rowStatus: StoreFetchingStatus
    let statType: StatType
    let statSection: StatSection?

    private let noDataRow = StatsNoDataRow.loadFromNib()

    // MARK: - Hashable

    static func == (lhs: StatsErrorRow, rhs: StatsErrorRow) -> Bool {
        return lhs.rowStatus == rhs.rowStatus &&
            lhs.statType == rhs.statType &&
            lhs.statSection == rhs.statSection
    }

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

extension StatsLastPostInsight: Equatable {
    public static func == (lhs: StatsLastPostInsight, rhs: StatsLastPostInsight) -> Bool {
        return lhs.title == rhs.title &&
               lhs.url == rhs.url &&
               lhs.publishedDate == rhs.publishedDate &&
               lhs.likesCount == rhs.likesCount &&
               lhs.commentsCount == rhs.commentsCount &&
               lhs.viewsCount == rhs.viewsCount &&
               lhs.postID == rhs.postID &&
               lhs.featuredImageURL == rhs.featuredImageURL
    }
}

extension StatsPostViews: Equatable {
    public static func == (lhs: StatsPostViews, rhs: StatsPostViews) -> Bool {
        return lhs.period == rhs.period &&
               lhs.date == rhs.date &&
               lhs.viewsCount == rhs.viewsCount
    }
}

extension StatsWeeklyBreakdown: Equatable {
    public static func == (lhs: StatsWeeklyBreakdown, rhs: StatsWeeklyBreakdown) -> Bool {
        return lhs.startDay == rhs.startDay &&
               lhs.endDay == rhs.endDay &&
               lhs.totalViewsCount == rhs.totalViewsCount &&
               lhs.averageViewsCount == rhs.averageViewsCount &&
               lhs.changePercentage == rhs.changePercentage &&
               lhs.days == rhs.days
    }
}

extension StatsPostDetails: Equatable {
    public static func == (lhs: StatsPostDetails, rhs: StatsPostDetails) -> Bool {
        return lhs.fetchedDate == rhs.fetchedDate &&
               lhs.totalViewsCount == rhs.totalViewsCount &&
               lhs.recentWeeks == rhs.recentWeeks &&
               lhs.dailyAveragesPerMonth == rhs.dailyAveragesPerMonth &&
               lhs.monthlyBreakdown == rhs.monthlyBreakdown &&
               lhs.lastTwoWeeks == rhs.lastTwoWeeks
    }
}

extension PostingStreakEvent: Equatable {
    public static func == (lhs: PostingStreakEvent, rhs: PostingStreakEvent) -> Bool {
        return lhs.date == rhs.date &&
               lhs.postCount == rhs.postCount
    }
}

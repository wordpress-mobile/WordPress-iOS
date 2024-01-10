import Foundation
import DGCharts
import Kanvas

// MARK: - StatsInsightsFilterDimension

enum StatsInsightsFilterDimension: Int, CaseIterable {
    case views = 0, visitors
}

extension StatsInsightsFilterDimension {
    var accessibleDescription: String {
        switch self {
        case .views:
            return NSLocalizedString("Line Chart depicting Views for insights.", comment: "This description is used to set the accessibility label for the Insights chart, with Views selected.")
        case .visitors:
            return NSLocalizedString("Line Chart depicting Visitors for insights.", comment: "This description is used to set the accessibility label for the Insights chart, with Visitors selected.")
        }
    }

    var analyticsProperty: String {
        switch self {
        case .views:
            return "views"
        case .visitors:
            return "visitors"
        }
    }
}

// MARK: - InsightsLineChart

class InsightsLineChart {

    private let rawChartData: [StatsSummaryTimeIntervalDataAsAWeek]
    private var filterDimension: StatsInsightsFilterDimension

    private(set) var lineChartData: [LineChartDataConvertible] = []
    private(set) var lineChartStyling: [LineChartStyling] = []

    init(data: [StatsSummaryTimeIntervalDataAsAWeek], filterDimension: StatsInsightsFilterDimension = .views) {
        rawChartData = data
        self.filterDimension = filterDimension

        let (data, styling) = transform()

        lineChartData = data
        lineChartStyling = styling
    }

    /// Transforms the raw data into the line chart data and styling.
    /// similar to PeriodChart transform
    /// - Returns: A tuple containing the line chart data and styling.
    func transform() -> (lineChartData: [LineChartDataConvertible], lineChartStyling: [LineChartStyling]) {
        var thisWeekEntries = [ChartDataEntry]()
        var prevWeekEntries = [ChartDataEntry]()

        switch filterDimension {
        case .views:
            (thisWeekEntries, prevWeekEntries) = filterData(path: \StatsSummaryData.viewsCount)
        case .visitors:
            (thisWeekEntries, prevWeekEntries) = filterData(path: \StatsSummaryData.visitorsCount)
        }

        let chartData = createLineChartData(thisWeekEntries: thisWeekEntries, prevWeekEntries: prevWeekEntries)
        let lineChartDataConvertibles = createLineChartDataConvertibles(chartData: chartData)

        let chartStyling: [LineChartStyling] = [
            ViewsInsightsLineChartStyling(primaryLineColor: Constants.primaryLineColorViews,
                    secondaryLineColor: Constants.secondaryLineColor,
                    primaryHighlightColor: Constants.primaryHighlightColor),
            VisitorsInsightsLineChartStyling(primaryLineColor: Constants.primaryLineColorVisitors,
                    secondaryLineColor: Constants.secondaryLineColor,
                    primaryHighlightColor: Constants.primaryHighlightColor),
        ]

        return (lineChartDataConvertibles, chartStyling)
    }

    func createLineChartData(thisWeekEntries: [ChartDataEntry], prevWeekEntries: [ChartDataEntry]) -> [LineChartData] {
        var chartData = [LineChartData]()

        let thisWeekDataSet = LineChartDataSet(entries: thisWeekEntries,
                label: NSLocalizedString("stats.insights.accessibility.label.viewsVisitorsLastDays", value: "Last 7-days", comment: "Accessibility label used for distinguishing Views and Visitors in the Stats → Insights Views Visitors Line chart."))
        let prevWeekDataSet = LineChartDataSet(entries: prevWeekEntries,
                label: NSLocalizedString("stats.insights.accessibility.label.viewsVisitorsPreviousDays", value: "Previous 7-days", comment: "Accessibility label used for distinguishing Views and Visitors in the Stats → Insights Views Visitors Line chart."))
        let viewsDataSets = [ thisWeekDataSet, prevWeekDataSet ]
        let viewsChartData = LineChartData(dataSets: viewsDataSets)
        chartData.append(viewsChartData)

        return chartData
    }

    func createLineChartDataConvertibles(chartData: [LineChartData]) -> [LineChartDataConvertible] {
        var lineChartDataConvertibles = [LineChartDataConvertible]()

        for filterDimension in StatsInsightsFilterDimension.allCases {
            let filterIndex = filterDimension.rawValue

            let accessibleDescription = filterDimension.accessibleDescription
            let data = chartData[filterIndex]
            let insightsChartData = InsightsLineChartData(accessibilityDescription: accessibleDescription, lineChartData: data)

            lineChartDataConvertibles.append(insightsChartData)
            break
        }

        return lineChartDataConvertibles
    }

    func filterData(path: KeyPath<StatsSummaryData, Int>) -> (thisWeekEntries: [ChartDataEntry], prevWeekEntries: [ChartDataEntry]) {
        var thisWeekEntries = [ChartDataEntry]()
        var prevWeekEntries = [ChartDataEntry]()

        rawChartData.forEach { statsSummaryTimeIntervalDataAsAWeek in
            switch statsSummaryTimeIntervalDataAsAWeek {
            case .thisWeek(let data):
                for (index, statsSummaryData) in data.summaryData.enumerated() {
                    thisWeekEntries.append(ChartDataEntry(x: Double(index), y: Double(statsSummaryData[keyPath: path])))
                }
            case .prevWeek(let data):
                for (index, statsSummaryData) in data.summaryData.enumerated() {
                    prevWeekEntries.append(ChartDataEntry(x: Double(index), y: Double(statsSummaryData[keyPath: path])))
                }
            }
        }

        return (thisWeekEntries: thisWeekEntries, prevWeekEntries: prevWeekEntries)
    }
}

private extension InsightsLineChart {
    enum Constants {
        static let primaryHighlightColor: UIColor = UIColor(red: 209.0/255.0, green: 209.0/255.0, blue: 214.0/255.0, alpha: 1.0)
        static let secondaryLineColor: UIColor = UIColor(light: .textQuaternary, dark: .textTertiary)
        static let primaryLineColorViews: UIColor = UIColor(light: .muriel(name: .blue, .shade50), dark: .muriel(name: .blue, .shade50))
        static let primaryLineColorVisitors: UIColor = UIColor(light: .muriel(name: .purple, .shade50), dark: .muriel(name: .purple, .shade50))
    }
}

// MARK: - InsightsLineChartData

private struct InsightsLineChartData: LineChartDataConvertible {
    let accessibilityDescription: String
    let lineChartData: LineChartData
}

// MARK: - ViewsInsightsLineChartStyling

private struct ViewsInsightsLineChartStyling: LineChartStyling {
    let primaryLineColor: UIColor
    let secondaryLineColor: UIColor?
    let primaryHighlightColor: UIColor?
    let labelColor: UIColor                         = UIColor(light: .secondaryLabel, dark: .tertiaryLabel)
    let legendColor: UIColor?                       = .primary(.shade60)
    let legendTitle: String?                        = NSLocalizedString("Views", comment: "Title for Views count in the legend of the Stats Insights views and visitors line chart")
    let lineColor: UIColor                          = .neutral(.shade5)
    let yAxisValueFormatter: AxisValueFormatter    = VerticalAxisFormatter()
}

// MARK: - VisitorsInsightsLineChartStyling

private struct VisitorsInsightsLineChartStyling: LineChartStyling {
    let primaryLineColor: UIColor
    let secondaryLineColor: UIColor?
    let primaryHighlightColor: UIColor?
    let labelColor: UIColor                         = UIColor(light: .secondaryLabel, dark: .tertiaryLabel)
    let legendColor: UIColor?                       = .primary(.shade60)
    let legendTitle: String?                        = NSLocalizedString("Visitors", comment: "Title for Visitors count in the legend of the Stats Insights views and visitors line chart")
    let lineColor: UIColor                          = .neutral(.shade5)
    let yAxisValueFormatter: AxisValueFormatter    = VerticalAxisFormatter()
}

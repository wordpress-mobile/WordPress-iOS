import Foundation
import Charts
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
}

// MARK: - InsightsLineChart

class InsightsLineChart {

    private let rawChartData: [StatsSummaryTimeIntervalDataAsAWeek]
    private var filterDimension: StatsInsightsFilterDimension

    private(set) var lineChartData: [LineChartDataConvertible] = []
    private(set) var lineChartStyling: [LineChartStyling] = []

    private(set) var thisWeekTotal: Int = 0
    private(set) var prevWeekTotal: Int = 0


    init(data: [StatsSummaryTimeIntervalDataAsAWeek], filterDimension: StatsInsightsFilterDimension = .views) {
        rawChartData = data
        self.filterDimension = filterDimension

        let (data, styling) = transform()

        lineChartData = data
        lineChartStyling = styling
    }

    private static let dataSetValueFormatter = DefaultValueFormatter(decimals: 0)

    func transform() -> (lineChartData: [LineChartDataConvertible], lineChartStyling: [LineChartStyling]) {
        var thisWeekEntries = [ChartDataEntry]()
        var prevWeekEntries = [ChartDataEntry]()

        switch filterDimension {
        case .views:
            rawChartData.forEach { statsSummaryTimeIntervalDataAsAWeek in
                switch statsSummaryTimeIntervalDataAsAWeek {
                case .thisWeek(let data):
                    thisWeekTotal = data.summaryData.compactMap({$0.viewsCount}).reduce(0, +)

                    for (index, statsSummaryData) in data.summaryData.enumerated() {
                        thisWeekEntries.append(ChartDataEntry(x: Double(index), y: Double(statsSummaryData.viewsCount)))
                    }
                case .prevWeek(let data):
                    prevWeekTotal = data.summaryData.compactMap({$0.viewsCount}).reduce(0, +)

                    for (index, statsSummaryData) in data.summaryData.enumerated() {
                        prevWeekEntries.append(ChartDataEntry(x: Double(index), y: Double(statsSummaryData.viewsCount)))
                    }
                }
            }
        case .visitors:
            rawChartData.forEach { statsSummaryTimeIntervalDataAsAWeek in
                switch statsSummaryTimeIntervalDataAsAWeek {
                case .thisWeek(let data):
                    thisWeekTotal = data.summaryData.compactMap({$0.visitorsCount}).reduce(0, +)

                    for (index, statsSummaryData) in data.summaryData.enumerated() {
                        thisWeekEntries.append(ChartDataEntry(x: Double(index), y: Double(statsSummaryData.visitorsCount)))
                    }
                case .prevWeek(let data):
                    prevWeekTotal = data.summaryData.compactMap({$0.visitorsCount}).reduce(0, +)

                    for (index, statsSummaryData) in data.summaryData.enumerated() {
                        prevWeekEntries.append(ChartDataEntry(x: Double(index), y: Double(statsSummaryData.visitorsCount)))
                    }
                }
            }
        }

        var chartData = [LineChartData]()

        let thisWeekDataSet = LineChartDataSet(values: thisWeekEntries,
                label: NSLocalizedString("This Week", comment: "Accessibility label used for distinguishing Views and Visitors in the Stats → Insights Views Visitors Line chart."))
        let prevWeekDataSet = LineChartDataSet(values: prevWeekEntries,
                label: NSLocalizedString("Previous Week", comment: "Accessibility label used for distinguishing Views and Visitors in the Stats → Insights Views Visitors Line chart."))
        let viewsDataSets = [ thisWeekDataSet, prevWeekDataSet ]
        let viewsChartData = LineChartData(dataSets: viewsDataSets)
        chartData.append(viewsChartData)

        var lineChartDataConvertibles = [LineChartDataConvertible]()
        for filterDimension in StatsInsightsFilterDimension.allCases {
            let filterIndex = filterDimension.rawValue

            let accessibleDescription = filterDimension.accessibleDescription
            let data = chartData[filterIndex]
            let insightsChartData = InsightsLineChartData(accessibilityDescription: accessibleDescription, lineChartData: data)

            lineChartDataConvertibles.append(insightsChartData)
            break
        }

        let horizontalAxisFormatter = HorizontalAxisFormatter(initialDateInterval: 1.0, period: .day)
        let chartStyling: [LineChartStyling] = [
            ViewsInsightsLineChartStyling(primaryLineColor: primaryLineColor(forFilterDimension: .views),
                    secondaryLineColor: secondaryLineColor(),
                    primaryHighlightColor: primaryHighlightColor()),
            VisitorsInsightsLineChartStyling(primaryLineColor: primaryLineColor(forFilterDimension: .visitors),
                    secondaryLineColor: secondaryLineColor(),
                    primaryHighlightColor: primaryHighlightColor()),
        ]

        return (lineChartDataConvertibles, chartStyling)
    }

    func primaryLineColor(forFilterDimension filterDimension: StatsInsightsFilterDimension) -> UIColor {
        switch filterDimension {
        case .views:
            return UIColor(light: .muriel(name: .blue, .shade50), dark: .muriel(name: .blue, .shade50))
        case .visitors:
            return UIColor(light: .muriel(name: .purple, .shade50), dark: .muriel(name: .purple, .shade50))
        }
    }

    func secondaryLineColor() -> UIColor {
        return  UIColor(light: .textQuaternary, dark: .textTertiary)
    }

    func primaryHighlightColor() -> UIColor? {
        return Constants.primaryHighlightColor
    }
}

private extension InsightsLineChart {
    enum Constants {
        static var primaryHighlightColor: UIColor {
            return UIColor(red: 209.0/255.0, green: 209.0/255.0, blue: 214.0/255.0, alpha: 1.0)
        }
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
    let legendTitle: String?                        = NSLocalizedString("Views", comment: "This appears in the legend of the insights line chart")
    let lineColor: UIColor                          = .neutral(.shade5)
    let yAxisValueFormatter: IAxisValueFormatter    = VerticalAxisFormatter()
}

// MARK: - VisitorsInsightsLineChartStyling

private struct VisitorsInsightsLineChartStyling: LineChartStyling {
    let primaryLineColor: UIColor
    let secondaryLineColor: UIColor?
    let primaryHighlightColor: UIColor?
    let labelColor: UIColor                         = UIColor(light: .secondaryLabel, dark: .tertiaryLabel)
    let legendColor: UIColor?                       = .primary(.shade60)
    let legendTitle: String?                        = NSLocalizedString("Visitors", comment: "This appears in the legend of the insights line chart")
    let lineColor: UIColor                          = .neutral(.shade5)
    let yAxisValueFormatter: IAxisValueFormatter    = VerticalAxisFormatter()
}

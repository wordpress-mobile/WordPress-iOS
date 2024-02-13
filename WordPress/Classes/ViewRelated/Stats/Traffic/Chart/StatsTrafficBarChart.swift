import Foundation
import DGCharts
import DesignSystem

struct StatsTrafficBarChart {
    let barChartData: [BarChartDataConvertible]
    let barChartStyling: [StatsTrafficBarChartStyling]

    init(data: StatsSummaryTimeIntervalData) {
        let transformer = StatsTrafficBarChartDataTransformer(data: data)
        self.barChartData = transformer.transformToBarChartData()
        self.barChartStyling = transformer.transformToBarChartStyling()
    }
}

// MARK: - StatsTrafficBarChartData

private struct StatsTrafficBarChartData: BarChartDataConvertible {
    let accessibilityDescription: String
    let barChartData: BarChartData
}

// MARK: - StatsTrafficBarChartDataTransformer

private struct StatsTrafficBarChartDataTransformer {
    private let dataSetValueFormatter = DefaultValueFormatter(decimals: 0)
    private let data: StatsSummaryTimeIntervalData

    init(data: StatsSummaryTimeIntervalData) {
        self.data = data
    }

    func transformToBarChartData() -> [BarChartDataConvertible] {
        let summaryData = data.summaryData

        var tabsDataEntries: [StatsTrafficBarChartTabs.CountKeyPath: [BarChartDataEntry]] = [:]
        let tabsTotals = StatsTrafficBarChartTabs.allCases.reduce(into: [:]) { totals, tab in
            totals[tab.count] = summaryData.compactMap { $0[keyPath: tab.count] }.reduce(0, +)
        }

        let emptyChartBarHeight = StatsTrafficBarChartView.emptyChartBarHeight

        for (x, data) in summaryData.enumerated() {
            for tab in StatsTrafficBarChartTabs.allCases {
                // If the chart has no data, show "stub" bars
                let entry = BarChartDataEntry(x: Double(x), y: tabsTotals[tab.count, default: 0] > 0 ? Double(data[keyPath: tab.count]) : emptyChartBarHeight)
                tabsDataEntries[tab.count, default: []].append(entry)
            }
        }

        return StatsTrafficBarChartTabs.allCases.map { tab in
            let chartData = BarChartData(entries: tabsDataEntries[tab.count, default: []], valueFormatter: dataSetValueFormatter)
            let statsTafficBarChartData = StatsTrafficBarChartData(accessibilityDescription: tab.accessibleDescription, barChartData: chartData)
            return statsTafficBarChartData
        }
    }

    func transformToBarChartStyling() -> [StatsTrafficBarChartStyling] {
        var xAxisIndexToDate: [Int: TimeInterval] = [:]

        for (x, data) in data.summaryData.enumerated() {
            let dateInterval = data.periodStartDate.timeIntervalSince1970
            xAxisIndexToDate[x] = dateInterval
        }

        let formatter = StatsTrafficHorizontalAxisFormatter(period: data.period, xAxisIndexToDate: xAxisIndexToDate)
        let styling = StatsTrafficBarChartStyle(xAxisValueFormatter: formatter)
        return Array(repeating: styling, count: StatsTrafficBarChartTabs.allCases.count)
    }
}

// MARK: - StatsTrafficBarChartStyling

protocol StatsTrafficBarChartStyling {
    var primaryBarColor: UIColor { get }
    var labelColor: UIColor { get }
    var lineColor: UIColor { get }
    var xAxisValueFormatter: AxisValueFormatter { get }
    var yAxisValueFormatter: AxisValueFormatter { get }
}

private struct StatsTrafficBarChartStyle: StatsTrafficBarChartStyling {
    let primaryBarColor: UIColor = UIColor(red: 6/255, green: 116/255, blue: 196/255, alpha: 1.0)
    let labelColor: UIColor = UIColor.DS.Foreground.secondary
    let lineColor: UIColor = UIColor.DS.Foreground.tertiary
    let xAxisValueFormatter: AxisValueFormatter
    let yAxisValueFormatter: AxisValueFormatter = StatsTrafficVerticalAxisFormatter()
}

// MARK: - Axis Formatter

final class StatsTrafficHorizontalAxisFormatter: AxisValueFormatter {

    // MARK: Properties

    private let period: StatsPeriodUnit
    private let xAxisIndexToDate: [Int: TimeInterval]

    private lazy var calendar = Calendar.current

    // MARK: HorizontalAxisFormatter

    init(
        period: StatsPeriodUnit = .day,
        xAxisIndexToDate: [Int: TimeInterval] = [:]
    ) {
        self.period = period
        self.xAxisIndexToDate = xAxisIndexToDate
    }

    // MARK: AxisValueFormatter

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        guard let value = xAxisIndexToDate[Int(value)] else {
            return ""
        }

        let date = Date(timeIntervalSince1970: value)

        switch period {
        case .day:
            return labelForDay(date)
        case .week:
            return labelForWeek(date)
        case .month:
            return labelForMonth(date)
        case .year:
            return labelForYear(date)

        }
    }

    private func labelForDay(_ date: Date) -> String {
        let dayComponent = calendar.component(.day, from: date)
        return "\(dayComponent)"
    }

    private func labelForWeek(_ date: Date) -> String {
        guard
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)),
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
            return ""
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        dateFormatter.locale = .current
        return "\(dateFormatter.string(from: startOfWeek))-\(dateFormatter.string(from: endOfWeek))"
    }

    private func labelForMonth(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "LLLL"
        dateFormatter.locale = .current
        let fullMonthName = dateFormatter.string(from: date)
        return String(fullMonthName.prefix(1))
    }

    private func labelForYear(_ date: Date) -> String {
        let dayComponent = calendar.component(.year, from: date)
        return "\(dayComponent)"
    }
}

// MARK: - VerticalAxisFormatter

final class StatsTrafficVerticalAxisFormatter: AxisValueFormatter {

    // MARK: Properties

    private let largeValueFormatter = LargeValueFormatter()

    // MARK: AxisValueFormatter

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        if value <= 0.0 {
            return "0"
        }

        return largeValueFormatter.stringForValue(value, axis: axis)
    }

    // Matches WPAndroid behavior to produce neater rounded values on
    // the vertical axis.
    static func roundUpAxisMaximum(_ input: Double) -> Double {
        if input > 100 {
            return roundUpAxisMaximum(input / 10) * 10
        } else {
            for i in 1..<25 {
                let limit = Double(4 * i)
                if input < limit {
                    return limit
                }
            }
            return Double(100)
        }
    }
}


import DGCharts

// MARK: - Charts extensions

extension BarChartData {
    convenience init(entries: [BarChartDataEntry], valueFormatter: ValueFormatter) {
        let dataSet = BarChartDataSet(entries: entries, valueFormatter: valueFormatter)
        self.init(dataSets: [dataSet])
    }
}

extension BarChartDataSet {
    convenience init(entries: [BarChartDataEntry], label: String = "", valueFormatter: ValueFormatter) {
        self.init(entries: entries, label: label)
        self.valueFormatter = valueFormatter
    }
}

// MARK: - Charts protocols

/// Describes the visual appearance of a BarChartView.
///
protocol BarChartStyling {

    /// This corresponds to the primary bar color.
    var primaryBarColor: UIColor { get }

    /// This bar color is used if bars are overlayed.
    var secondaryBarColor: UIColor? { get }

    /// This corresponds to the color of a single selected bar
    var primaryHighlightColor: UIColor? { get }

    /// This corresponds to the color of a second selected bar; currently only applicable when Views/Visitors overlaid.
    var secondaryHighlightColor: UIColor? { get }

    /// This corresponds to the color of labels on the chart
    var labelColor: UIColor { get }

    /// This corresponds to the legend color; currently only applicable when Views/Visitors overlaid.
    var legendColor: UIColor? { get }

    /// If specified, a legend will be presented with this value. It maps to the secondary bar color above.
    var legendTitle: String? { get }

    /// This corresponds to the color of lines on the chart
    var lineColor: UIColor { get }

    /// Formatter for x-axis values
    var xAxisValueFormatter: AxisValueFormatter { get }

    /// Formatter for y-axis values
    var yAxisValueFormatter: AxisValueFormatter { get }
}

protocol LineChartStyling {

    /// This corresponds to the primary bar color.
    var primaryLineColor: UIColor { get }

    /// This bar color is used if bars are overlayed.
    var secondaryLineColor: UIColor? { get }

    /// This corresponds to the color of a single selected point
    var primaryHighlightColor: UIColor? { get }

    /// This corresponds to the color of axis labels on the chart
    var labelColor: UIColor { get }

    /// If specified, a legend will be presented with this value. It maps to the secondary bar color above.
    var legendTitle: String? { get }

    /// This corresponds to the color of axis and grid lines on the chart
    var lineColor: UIColor { get }

    /// Formatter for y-axis values
    var yAxisValueFormatter: AxisValueFormatter { get }
}

/// Transforms a given data set for consumption by BarChartView in the Charts framework.
///
protocol BarChartDataConvertible {

    /// Describe the chart for VoiceOver usage
    var accessibilityDescription: String { get }

    /// Adapts the original data format for consumption by the Charts framework.
    var barChartData: BarChartData { get }
}

/// Transforms a given data set for consumption by LineChartView in the Charts framework.
///
protocol LineChartDataConvertible {

    /// Describe the chart for VoiceOver usage
    var accessibilityDescription: String { get }

    /// Adapts the original data format for consumption by the Charts framework.
    var lineChartData: LineChartData { get }
}

// MARK: - Charts & analytics

/// Vends property values for analytics events that use granularity.
///
enum BarChartAnalyticsPropertyGranularityValue: String, CaseIterable {
    case days, weeks, months, years
}

enum LineChartAnalyticsPropertyGranularityValue: String, CaseIterable {
    case days, weeks, months, years
}

extension StatsPeriodUnit {
    var analyticsGranularity: BarChartAnalyticsPropertyGranularityValue {
        switch self {
        case .day:
            return .days
        case .week:
            return .weeks
        case .month:
            return .months
        case .year:
            return .years
        }
    }

    var analyticsGranularityLine: LineChartAnalyticsPropertyGranularityValue {
        switch self {
        case .day:
            return .days
        case .week:
            return .weeks
        case .month:
            return .months
        case .year:
            return .years
        }
    }
}

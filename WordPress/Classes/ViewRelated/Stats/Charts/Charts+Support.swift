
import Charts

// MARK: - Charts extensions

extension BarChartData {
    convenience init(entries: [BarChartDataEntry], valueFormatter: IValueFormatter? = nil) {
        let dataSet = BarChartDataSet(values: entries, label: nil, valueFormatter: valueFormatter)
        self.init(dataSets: [dataSet])
    }
}

extension BarChartDataSet {
    convenience init(values: [BarChartDataEntry], label: String?, valueFormatter: IValueFormatter?) {
        self.init(values: values, label: label)
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
    var xAxisValueFormatter: IAxisValueFormatter { get }

    /// Formatter for y-axis values
    var yAxisValueFormatter: IAxisValueFormatter { get }
}

/// Transforms a given data set for consumption by BarChartView in the Charts framework.
///
protocol BarChartDataConvertible {

    /// Describe the chart for VoiceOver usage
    var accessibilityDescription: String { get }

    /// Adapts the original data format for consumption by the Charts framework.
    var barChartData: BarChartData { get }
}

// MARK: - Charts & analytics

/// Vends property values for analytics events that use granularity.
///
enum BarChartAnalyticsPropertyGranularityValue: String, CaseIterable {
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
}

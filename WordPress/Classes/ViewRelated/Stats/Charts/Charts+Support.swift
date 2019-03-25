
import Charts

// MARK: - Charts extensions

extension BarChartData {
    convenience init(entries: [BarChartDataEntry]) {
        let dataSet = BarChartDataSet(values: entries)
        self.init(dataSets: [dataSet])
    }
}

extension BarChartDataSet {
    convenience init(values: [BarChartDataEntry]) {
        self.init(values: values, label: nil)
    }
}

// MARK: - Charts protocols

/// Describes the visual appearance of a BarChartView. Implementation TBD.
///
protocol BarChartStyling {

    /// This corresponds to the bar color
    var barColor: UIColor { get }

    /// This corresponds to the color of a selected bar
    var highlightColor: UIColor? { get }

    /// This corresponds to the color of labels on the chart
    var labelColor: UIColor { get }

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
    var barChartData: BarChartData { get }
}

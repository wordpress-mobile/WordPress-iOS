
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

extension NSUIColor {
    static let chartColor = UIColor(red: 135/255.0, green: 166/255.0, blue: 188/255.0, alpha: 255.0/255.0)

    static let highlightColor = UIColor(red: 245/255.0, green: 131/255.0, blue: 53/255.0, alpha: 255.0/255.0)
}

// MARK: - Charts protocols

/// Describes the visual appearance of a BarChartView. Implementation TBD.
///
protocol BarChartStyling {

    /// This corresponds to the color of other chart "chrome" (i.e., axes, labels, etc.)
    var adornmentColor: UIColor { get }

    /// This corresponds to the bar color
    var barColor: UIColor { get }

    /// This corresponds to the color of a selected bar
    var highlightColor: UIColor? { get }

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

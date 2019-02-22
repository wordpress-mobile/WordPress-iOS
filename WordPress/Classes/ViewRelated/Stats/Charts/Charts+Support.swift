
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
}

// MARK: - Charts protocols

/// Describes the visual appearance of a BarChartView. Implementation TBD.
///
protocol BarChartStyling {

    var adornmentColor: UIColor { get }

    var barColor: UIColor { get }

    var xAxisValueFormatter: IAxisValueFormatter { get }

    var yAxisValueFormatter: IAxisValueFormatter { get }
}

/// Transforms a given data set for consumption by BarChartView in the Charts framework.
///
protocol BarChartDataConvertible {
    var barChartData: BarChartData { get }
}

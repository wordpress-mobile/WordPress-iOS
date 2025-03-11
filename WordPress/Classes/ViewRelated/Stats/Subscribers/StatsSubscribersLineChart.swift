import Foundation
import DGCharts

private struct SubscriberLineChartData: LineChartDataConvertible {
    let accessibilityDescription: String
    let lineChartData: LineChartData
}

class StatsSubscribersLineChart {

    let lineChartData: LineChartDataConvertible
    let lineChartStyling: LineChartStyling

    init(counts: [Int]) {
        let chartEntries = counts.enumerated().map { index, count in
            ChartDataEntry(x: Double(index), y: Double(count))
        }
        let dataSet = LineChartDataSet(entries: chartEntries)
        let chartData = LineChartData(dataSets: [dataSet])
        lineChartData = SubscriberLineChartData(accessibilityDescription: "Subscriber Charts", lineChartData: chartData)
        lineChartStyling = SubscribersLineChartStyling()
    }
}

// MARK: - StatsSubscribersLineChartStyling

private struct SubscribersLineChartStyling: LineChartStyling {
    let primaryLineColor: UIColor = UIAppColor.blue(.shade50)
    let secondaryLineColor: UIColor? = nil
    let primaryHighlightColor: UIColor? = UIColor(red: 209.0 / 255.0, green: 209.0 / 255.0, blue: 214.0 / 255.0, alpha: 1.0)
    let labelColor: UIColor = UIColor(light: .secondaryLabel, dark: .tertiaryLabel)
    let legendColor: UIColor? = nil
    let legendTitle: String? = NSLocalizedString("stats.subscribers.chart.legend", value: "Subscribers", comment: "Title for the legend of the Stats Subscribers line chart.")
    let lineColor: UIColor = UIAppColor.neutral(.shade5)
    let yAxisValueFormatter: AxisValueFormatter = VerticalAxisFormatter()
}

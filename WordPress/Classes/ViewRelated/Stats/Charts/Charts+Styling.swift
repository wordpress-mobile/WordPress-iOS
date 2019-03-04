
import Foundation

import Charts

// MARK: - PostSummaryStyling

class PostSummaryStyling: BarChartStyling {
    let barColor: UIColor
    let highlightColor: UIColor?
    let labelColor: UIColor
    let lineColor: UIColor
    let xAxisValueFormatter: IAxisValueFormatter
    let yAxisValueFormatter: IAxisValueFormatter

    init(barColor: UIColor, highlightColor: UIColor?, labelColor: UIColor, lineColor: UIColor, xAxisValueFormatter: IAxisValueFormatter, yAxisValueFormatter: IAxisValueFormatter) {
        self.barColor               = barColor
        self.highlightColor         = highlightColor
        self.labelColor             = labelColor
        self.lineColor              = lineColor
        self.xAxisValueFormatter    = xAxisValueFormatter
        self.yAxisValueFormatter    = yAxisValueFormatter
    }
}


import Foundation

import Charts

// MARK: - PostSummaryStyling

class PostSummaryStyling: BarChartStyling {
    let adornmentColor: UIColor
    let barColor: UIColor
    let highlightColor: UIColor?
    let xAxisValueFormatter: IAxisValueFormatter
    let yAxisValueFormatter: IAxisValueFormatter

    init(adornmentColor: UIColor, barColor: UIColor, highlightColor: UIColor?, xAxisValueFormatter: IAxisValueFormatter, yAxisValueFormatter: IAxisValueFormatter) {
        self.adornmentColor         = adornmentColor
        self.barColor               = barColor
        self.highlightColor         = highlightColor
        self.xAxisValueFormatter    = xAxisValueFormatter
        self.yAxisValueFormatter    = yAxisValueFormatter
    }
}

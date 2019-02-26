
import Foundation

import Charts

// MARK: - LatestPostSummaryStyling

struct LatestPostSummaryStyling: BarChartStyling {
    let adornmentColor: UIColor
    let barColor: UIColor
    let xAxisValueFormatter: IAxisValueFormatter
    let yAxisValueFormatter: IAxisValueFormatter
}

extension LatestPostSummaryStyling {
    init(xAxisFormatter: IAxisValueFormatter, yAxisFormatter: IAxisValueFormatter) {
        self.init(
            adornmentColor: NSUIColor.chartColor,
            barColor: WPStyleGuide.wordPressBlue(),
            xAxisValueFormatter: xAxisFormatter,
            yAxisValueFormatter: yAxisFormatter)
    }
}

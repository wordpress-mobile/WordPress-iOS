
import Foundation

import Charts

// MARK: - PostSummaryStyling

struct PostSummaryStyling: BarChartStyling {
    let adornmentColor: UIColor
    let barColor: UIColor
    let xAxisValueFormatter: IAxisValueFormatter
    let yAxisValueFormatter: IAxisValueFormatter
}

// MARK: - LatestPostSummaryStyling

typealias LatestPostSummaryStyling = PostSummaryStyling

extension LatestPostSummaryStyling {
    init(xAxisFormatter: IAxisValueFormatter, yAxisFormatter: IAxisValueFormatter) {
        self.init(
            adornmentColor: NSUIColor.chartColor,
            barColor: WPStyleGuide.wordPressBlue(),
            xAxisValueFormatter: xAxisFormatter,
            yAxisValueFormatter: yAxisFormatter)
    }
}

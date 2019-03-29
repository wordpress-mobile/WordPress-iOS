
import Foundation

import Charts

// MARK: - ViewsPeriodPerformanceStyling

class ViewsPeriodPerformanceStyling: BarChartStyling {

    let primaryBarColor: UIColor
    let secondaryBarColor: UIColor?
    let primaryHighlightColor: UIColor?
    let secondaryHighlightColor: UIColor?
    let labelColor: UIColor
    let legendTitle: String?
    let lineColor: UIColor
    let xAxisValueFormatter: IAxisValueFormatter
    let yAxisValueFormatter: IAxisValueFormatter

    init(initialDateInterval: TimeInterval, highlightColor: UIColor? = nil) {
        let xAxisFormatter = HorizontalAxisFormatter(initialDateInterval: initialDateInterval)

        self.primaryBarColor            = WPStyleGuide.wordPressBlue()
        self.secondaryBarColor          = WPStyleGuide.darkBlue()
        self.primaryHighlightColor      = WPStyleGuide.jazzyOrange()
        self.secondaryHighlightColor    = WPStyleGuide.fireOrange()
        self.labelColor                 = WPStyleGuide.grey()
        self.legendTitle                = "Visitors"    // we do not localized stub data...
        self.lineColor                  = WPStyleGuide.greyLighten30()
        self.xAxisValueFormatter        = xAxisFormatter
        self.yAxisValueFormatter        = VerticalAxisFormatter()
    }
}

// MARK: - DefaultPeriodPerformanceStyling

class DefaultPeriodPerformanceStyling: BarChartStyling {

    let primaryBarColor: UIColor
    let secondaryBarColor: UIColor?
    let primaryHighlightColor: UIColor?
    let secondaryHighlightColor: UIColor?
    let labelColor: UIColor
    let legendTitle: String?
    let lineColor: UIColor
    let xAxisValueFormatter: IAxisValueFormatter
    let yAxisValueFormatter: IAxisValueFormatter

    init(initialDateInterval: TimeInterval, highlightColor: UIColor? = nil) {
        let xAxisFormatter = HorizontalAxisFormatter(initialDateInterval: initialDateInterval)

        self.primaryBarColor            = WPStyleGuide.wordPressBlue()
        self.secondaryBarColor          = WPStyleGuide.darkBlue()
        self.primaryHighlightColor      = WPStyleGuide.jazzyOrange()
        self.secondaryHighlightColor    = highlightColor
        self.labelColor                 = WPStyleGuide.grey()
        self.legendTitle                = nil
        self.lineColor                  = WPStyleGuide.greyLighten30()
        self.xAxisValueFormatter        = xAxisFormatter
        self.yAxisValueFormatter        = VerticalAxisFormatter()
    }
}

// MARK: - PostSummaryStyling

class PostSummaryStyling: BarChartStyling {

    let primaryBarColor: UIColor
    let secondaryBarColor: UIColor?
    let primaryHighlightColor: UIColor?
    let secondaryHighlightColor: UIColor?
    let labelColor: UIColor
    let legendTitle: String?
    let lineColor: UIColor
    let xAxisValueFormatter: IAxisValueFormatter
    let yAxisValueFormatter: IAxisValueFormatter

    init(barColor: UIColor, highlightColor: UIColor?, labelColor: UIColor, lineColor: UIColor, xAxisValueFormatter: IAxisValueFormatter, yAxisValueFormatter: IAxisValueFormatter) {
        self.primaryBarColor            = barColor
        self.secondaryBarColor          = nil
        self.primaryHighlightColor      = highlightColor
        self.secondaryHighlightColor    = nil
        self.labelColor                 = labelColor
        self.legendTitle                = nil
        self.lineColor                  = lineColor
        self.xAxisValueFormatter        = xAxisValueFormatter
        self.yAxisValueFormatter        = yAxisValueFormatter
    }
}

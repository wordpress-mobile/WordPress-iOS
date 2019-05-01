
import Foundation

import Charts

// MARK: - PostChart

class PostChart {

    private static let chartDescription = NSLocalizedString("Bar Chart depicting visitors for this post", comment: "This description is used to set the accessibility label for the chart in the Post Stats view.")

    private let rawPostViews: [StatsPostViews]
    private let transformedPostData: BarChartData

    let barChartStyling: BarChartStyling

    init(postViews: [StatsPostViews]) {
        self.rawPostViews = postViews

        let (data, styling) = PostChartDataTransformer.transform(postViews: postViews)

        self.transformedPostData = data
        self.barChartStyling = styling
    }
}

// MARK: - BarChartDataConvertible

extension PostChart: BarChartDataConvertible {
    var accessibilityDescription: String {
        return PostChart.chartDescription
    }

    var barChartData: BarChartData {
        return transformedPostData
    }
}

// MARK: - PostChartDataTransformer

private extension StatsPostViews {
    var postDateTimeInterval: TimeInterval? {
        let calendar = Calendar.autoupdatingCurrent

        if !date.isValidDate(in: calendar) {
            return nil
        }

        let theDate = Calendar.autoupdatingCurrent.date(from: date)
        return theDate?.timeIntervalSince1970
    }
}

class PostChartDataTransformer {
    static func transform(postViews: [StatsPostViews]) -> (barChartData: BarChartData, barChartStyling: BarChartStyling) {
        let data = postViews

        let firstDateInterval: TimeInterval
        let lastDateInterval: TimeInterval
        let effectiveWidth: Double

        if data.isEmpty {
            firstDateInterval = 0
            lastDateInterval = 0
            effectiveWidth = 1
        } else {
            firstDateInterval = data.first?.postDateTimeInterval ?? 0
            lastDateInterval = data.last?.postDateTimeInterval ?? 0

            let range = lastDateInterval - firstDateInterval

            let effectiveBars = Double(Double(data.count) * 1.2)

            effectiveWidth = range / effectiveBars
        }

        var entries = [BarChartDataEntry]()
        for datum in data {
            let dateInterval = datum.postDateTimeInterval ?? 0
            let offset = dateInterval - firstDateInterval

            let x = offset
            let y = Double(datum.viewsCount)
            let entry = BarChartDataEntry(x: x, y: y)

            entries.append(entry)
        }

        let chartData = BarChartData(entries: entries)
        chartData.barWidth = effectiveWidth

        let xAxisFormatter: IAxisValueFormatter = HorizontalAxisFormatter(initialDateInterval: firstDateInterval)
        let styling = PostChartStyling(xAxisValueFormatter: xAxisFormatter)

        return (chartData, styling)
    }
}

// MARK: - PostChartStyling

private struct PostChartStyling: BarChartStyling {
    let primaryBarColor: UIColor                    = WPStyleGuide.wordPressBlue()
    let secondaryBarColor: UIColor?                 = nil
    let primaryHighlightColor: UIColor?             = WPStyleGuide.jazzyOrange()
    let secondaryHighlightColor: UIColor?           = nil
    let labelColor: UIColor                         = WPStyleGuide.grey()
    let legendTitle: String?                        = nil
    let lineColor: UIColor                          = WPStyleGuide.greyLighten30()
    let xAxisValueFormatter: IAxisValueFormatter
    let yAxisValueFormatter: IAxisValueFormatter    = VerticalAxisFormatter()
}

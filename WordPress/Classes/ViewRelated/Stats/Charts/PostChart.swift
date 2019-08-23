import Foundation
import Charts

// MARK: - PostChartType

enum PostChartType {
    case latest
    case selected
}

extension PostChartType {
    var accessibleDescription: String {
        switch self {
        case .latest:
            return NSLocalizedString("Bar Chart depicting visitors for your latest post", comment: "This description is used to set the accessibility label for the chart in the Insights view.")
        case .selected:
            return NSLocalizedString("Bar Chart depicting visitors for this post", comment: "This description is used to set the accessibility label for the chart in the Post Stats view.")
        }
    }
}

extension PostChartType {
    var highlightColor: UIColor? {
        switch self {
        case .latest:
            return nil
        case .selected:
            return .accent(.shade30)
        }
    }
}

// MARK: - PostChart

final class PostChart {

    private let chartType: PostChartType
    private let rawPostViews: [StatsPostViews]
    private let transformedPostData: BarChartData

    let barChartStyling: BarChartStyling

    init(type: PostChartType = .selected, postViews: [StatsPostViews]) {
        chartType = type
        rawPostViews = postViews

        let (data, styling) = PostChartDataTransformer.transform(type: type, postViews: postViews)

        transformedPostData = data
        barChartStyling = styling
    }
}

// MARK: - BarChartDataConvertible

extension PostChart: BarChartDataConvertible {
    var accessibilityDescription: String {
        return chartType.accessibleDescription
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

private final class PostChartDataTransformer {
    static func transform(type: PostChartType, postViews: [StatsPostViews]) -> (barChartData: BarChartData, barChartStyling: BarChartStyling) {
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

        let totalViews = data.compactMap({$0.viewsCount}).reduce(0, +)

        var entries = [BarChartDataEntry]()
        for datum in data {
            let dateInterval = datum.postDateTimeInterval ?? 0
            let offset = dateInterval - firstDateInterval

            let x = offset
            // If the chart has no data, show "stub" bars
            let y = totalViews > 0 ? Double(datum.viewsCount) : StatsBarChartView.emptyChartBarHeight
            let entry = BarChartDataEntry(x: x, y: y)

            entries.append(entry)
        }

        let chartData = BarChartData(entries: entries)
        chartData.barWidth = effectiveWidth

        let xAxisFormatter: IAxisValueFormatter = HorizontalAxisFormatter(initialDateInterval: firstDateInterval)
        let styling = PostChartStyling(primaryBarColor: primaryBarColor(forCount: totalViews),
                                       primaryHighlightColor: primaryHighlightColor(forType: type, withCount: totalViews),
                                       xAxisValueFormatter: xAxisFormatter)

        return (chartData, styling)
    }

    static func primaryBarColor(forCount count: Int) -> UIColor {
        return count > 0 ? .primaryLight : .neutral(.shade0)
    }

    static func primaryHighlightColor(forType type: PostChartType, withCount count: Int) -> UIColor? {
        return count > 0 ? type.highlightColor : nil
    }

}

// MARK: - PostChartStyling

private struct PostChartStyling: BarChartStyling {
    let primaryBarColor: UIColor
    let secondaryBarColor: UIColor?                 = nil
    let primaryHighlightColor: UIColor?
    let secondaryHighlightColor: UIColor?           = nil
    let labelColor: UIColor                         = .neutral(.shade30)
    let legendColor: UIColor?                       = nil
    let legendTitle: String?                        = nil
    let lineColor: UIColor                          = .neutral(.shade5)
    let xAxisValueFormatter: IAxisValueFormatter
    let yAxisValueFormatter: IAxisValueFormatter    = VerticalAxisFormatter()
}

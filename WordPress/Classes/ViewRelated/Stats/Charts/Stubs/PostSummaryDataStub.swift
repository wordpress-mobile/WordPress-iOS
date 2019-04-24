
import Foundation

import Charts

// MARK: - PostSummaryDatum

struct PostSummaryDatum: Decodable {
    let date: Date
    let viewCount: Int

    private enum CodingKeys: String, CodingKey {
        case date       = "day"
        case viewCount  = "count"
    }
}

// MARK: - PostSummaryDataStub

class PostSummaryDataStub: DataStub<[PostSummaryDatum]> {
    private let postSummaryChartDescription: String

    init(fileName: String, description: String) {
        self.postSummaryChartDescription = description
        super.init([PostSummaryDatum].self, fileName: fileName)
    }

    var summaryData: [PostSummaryDatum] {
        return data as? [PostSummaryDatum] ?? []
    }
}

// MARK: - LatestPostSummaryDataStub

class LatestPostSummaryDataStub: PostSummaryDataStub {
    init() {
        let chartDescription = "Bar Chart depicting Views for the Latest Post"  // NB: we don't localize stub data
        super.init(fileName: "latestPost_data", description: chartDescription)
    }
}

// MARK: - SelectedPostSummaryDataStub

class SelectedPostSummaryDataStub: PostSummaryDataStub {
    init() {
        let chartDescription = "Bar Chart depicting Visitors for the Selected Post"  // NB: we don't localize stub data
        super.init(fileName: "selectedPost_data", description: chartDescription)
    }
}

// MARK: - BarChartDataConvertible

extension PostSummaryDataStub: BarChartDataConvertible {
    var accessibilityDescription: String {
        return postSummaryChartDescription
    }

    var barChartData: BarChartData {

        let data = summaryData

        // Our stub data is ordered
        let firstDateInterval: TimeInterval
        let lastDateInterval: TimeInterval
        let effectiveWidth: Double

        if data.isEmpty {
            firstDateInterval = 0
            lastDateInterval = 0
            effectiveWidth = 1
        } else {
            firstDateInterval = data.first!.date.timeIntervalSince1970
            lastDateInterval = data.last!.date.timeIntervalSince1970

            let range = lastDateInterval - firstDateInterval

            let effectiveBars = Double(Double(data.count) * 1.2)

            effectiveWidth = range / effectiveBars
        }

        var entries = [BarChartDataEntry]()
        for datum in data {
            let dateInterval = datum.date.timeIntervalSince1970
            let offset = dateInterval - firstDateInterval

            let x = offset
            let y = Double(datum.viewCount)
            let entry = BarChartDataEntry(x: x, y: y)

            entries.append(entry)
        }

        let chartData = BarChartData(entries: entries)
        chartData.barWidth = effectiveWidth

        return chartData
    }
}

// MARK: - PostSummaryStubStyling

extension PostSummaryStyling {
    convenience init(initialDateInterval: TimeInterval, highlightColor: UIColor? = nil) {
        let xAxisFormatter = HorizontalAxisFormatter(initialDateInterval: initialDateInterval)

        self.init(
            barColor: WPStyleGuide.wordPressBlue(),
            highlightColor: highlightColor,
            labelColor: WPStyleGuide.grey(),
            lineColor: WPStyleGuide.greyLighten30(),
            xAxisValueFormatter: xAxisFormatter,
            yAxisValueFormatter: VerticalAxisFormatter())
    }
}

// MARK: - LatestPostSummaryStyling

class LatestPostSummaryStyling: PostSummaryStyling {}

// MARK: - SelectedPostSummaryStyling

class SelectedPostSummaryStyling: PostSummaryStyling {
    convenience init(initialDateInterval: TimeInterval) {
        self.init(initialDateInterval: initialDateInterval, highlightColor: WPStyleGuide.jazzyOrange())
    }
}


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

// MARK: - LatestPostSummaryDataStub

class LatestPostSummaryDataStub: PostSummaryDataStub {
    init() {
        super.init(fileName: "latestPost_data")
    }
}

// MARK: - SelectedPostSummaryDataStub

class SelectedPostSummaryDataStub: PostSummaryDataStub {
    init() {
        super.init(fileName: "selectedPost_data")
    }
}

/// Stub structure informed by https://developer.wordpress.com/docs/api/1.1/get/sites/%24site/stats/post/%24post_id/
/// Values approximate what's depicted in Zeplin
///
class PostSummaryDataStub {

    private static let jsonFileExtension = "json"

    private(set) var data: [PostSummaryDatum]

    init(fileName: String) {
        let bundle = Bundle(for: type(of: self))

        guard let url = bundle.url(
            forResource: fileName,
            withExtension: PostSummaryDataStub.jsonFileExtension) else {

            fatalError("Failed to locate \(fileName).\(PostSummaryDataStub.jsonFileExtension) in bundle.")
        }

        guard let jsonData = try? Data(contentsOf: url) else {
            fatalError("Failed to parse \(fileName).\(PostSummaryDataStub.jsonFileExtension) as Data.")
        }

        let decoder = JSONDecoder()
        let dateFormatter = PostSummaryDateFormatter()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        guard let decoded = try? decoder.decode([PostSummaryDatum].self, from: jsonData) else {
            fatalError("Failed to decode \(fileName).\(PostSummaryDataStub.jsonFileExtension) from data")
        }

        self.data = decoded
    }
}

// MARK: - BarChartDataConvertible

extension PostSummaryDataStub: BarChartDataConvertible {
    var barChartData: BarChartData {

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

// MARK: - PostSummaryDateFormatter

private class PostSummaryDateFormatter: DateFormatter {
    override init() {
        super.init()

        self.locale = Locale(identifier: "en_US_POSIX")
        self.dateFormat = "yyyy-MM-dd"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - PostSummaryStubStyling

extension PostSummaryStyling {
    convenience init(initialDateInterval: TimeInterval, highlightColor: UIColor? = nil) {
        let xAxisFormatter = PostSummaryHorizontalAxisFormatter(initialDateInterval: initialDateInterval)

        self.init(
            adornmentColor: WPStyleGuide.greyLighten30(),
            barColor: WPStyleGuide.wordPressBlue(),
            highlightColor: highlightColor,
            xAxisValueFormatter: xAxisFormatter,
            yAxisValueFormatter: PostSummaryVerticalAxisFormatter())
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

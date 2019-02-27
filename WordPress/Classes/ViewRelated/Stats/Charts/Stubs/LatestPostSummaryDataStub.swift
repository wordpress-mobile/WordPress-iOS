
import Foundation

import Charts

// MARK: - LatestPostSummaryDatum

struct LatestPostSummaryDatum: Decodable {
    let date: Date
    let viewCount: Int

    private enum CodingKeys: String, CodingKey {
        case date       = "day"
        case viewCount  = "count"
    }
}

// MARK: - LatestPostSummaryDataStub

/// Stub structure informed by https://developer.wordpress.com/docs/api/1.1/get/sites/%24site/stats/post/%24post_id/
/// Values approximate what's depicted in Zeplin
///
class LatestPostSummaryDataStub {

    private static let jsonFileName        = "latestPost_data"
    private static let jsonFileExtension   = "json"

    private(set) var data: [LatestPostSummaryDatum]

    init() {
        let bundle = Bundle(for: type(of: self))

        guard let url = bundle.url(
            forResource: LatestPostSummaryDataStub.jsonFileName,
            withExtension: LatestPostSummaryDataStub.jsonFileExtension) else {

            fatalError("Failed to locate \(LatestPostSummaryDataStub.jsonFileName).\(LatestPostSummaryDataStub.jsonFileExtension) in bundle.")
        }

        guard let jsonData = try? Data(contentsOf: url) else {
            fatalError("Failed to parse \(LatestPostSummaryDataStub.jsonFileName).\(LatestPostSummaryDataStub.jsonFileExtension) as Data.")
        }

        let decoder = JSONDecoder()
        let dateFormatter = LatestPostSummaryDateFormatter()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        guard let decoded = try? decoder.decode([LatestPostSummaryDatum].self, from: jsonData) else {
            fatalError("Failed to decode \(LatestPostSummaryDataStub.jsonFileName).\(LatestPostSummaryDataStub.jsonFileExtension) from data")
        }

        self.data = decoded
    }
}

extension LatestPostSummaryDataStub: BarChartDataConvertible {
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

// MARK: - LatestPostSummaryDateFormatter

private class LatestPostSummaryDateFormatter: DateFormatter {
    override init() {
        super.init()

        self.locale = Locale(identifier: "en_US_POSIX")
        self.dateFormat = "yyyy-MM-dd"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - LatestPostSummaryStubHorizontalAxisFormatter

/// This formatter requires some explanation. The framework does not necessarily respond well to large values, and/or
/// large ranges of values as originally encountered using the naive TimeInterval representation of current dates.
/// The side effect is that bars appear quite narrow.
///
/// The bug is documented in the following issues:
/// https://github.com/danielgindi/Charts/issues/1716
/// https://github.com/danielgindi/Charts/issues/1742
/// https://github.com/danielgindi/Charts/issues/2410
/// https://github.com/danielgindi/Charts/issues/2680
///
/// The workaround employed here (recommended in 2410 above) relies on the time series data being ordered, and simply
/// transforms the adjusted values by the time interval associated with the first date in the series.
///
class LatestPostSummaryStubHorizontalAxisFormatter: IAxisValueFormatter {

    // MARK: Properties

    private let initialDateInterval: TimeInterval

    private lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM dd")

        return formatter
    }()

    // MARK: LatestPostSummaryStubHorizontalAxisFormatter

    init(initialDateInterval: TimeInterval) {
        self.initialDateInterval = initialDateInterval
    }

    // MARK: IAxisValueFormatter

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let adjustedValue = initialDateInterval + value
        let date = Date(timeIntervalSince1970: adjustedValue)
        let value = formatter.string(from: date)

        return value
    }
}

// MARK: - LatestPostSummaryStubVerticalAxisFormatter

class LatestPostSummaryStubVerticalAxisFormatter: IAxisValueFormatter {

    // MARK: Properties

    private lazy var formatter: NumberFormatter = {
        let formatter = NumberFormatter()

        formatter.maximumFractionDigits = 0

        return formatter
    }()

    // MARK: IAxisValueFormatter

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let number = NSNumber(value: value/1000)
        let value = formatter.string(from: number) ?? ""

        // This is, admittedly NOT locale-sensitive formatting approach.
        // It is stub data, and will be replaced with more robust code prior to shipping
        let formattedValue = "\(value)k"

        return formattedValue
    }
}

// MARK: - LatestPostSummaryStyling

typealias LatestPostSummaryStubStyling = LatestPostSummaryStyling

extension LatestPostSummaryStubStyling {
    init(initialDateInterval: TimeInterval) {
        let xAxisFormatter = LatestPostSummaryStubHorizontalAxisFormatter(initialDateInterval: initialDateInterval)
        let yAxisFormatter = LatestPostSummaryStubVerticalAxisFormatter()

        self.init(xAxisFormatter: xAxisFormatter, yAxisFormatter: yAxisFormatter)
    }
}

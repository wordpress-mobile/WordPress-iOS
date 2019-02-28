
import Foundation

import Charts

// MARK: - PostSummaryHorizontalAxisFormatter

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
class PostSummaryHorizontalAxisFormatter: IAxisValueFormatter {

    // MARK: Properties

    private let initialDateInterval: TimeInterval

    private lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM dd")

        return formatter
    }()

    // MARK: PostSummaryHorizontalAxisFormatter

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

// MARK: - PostSummaryVerticalAxisFormatter

class PostSummaryVerticalAxisFormatter: IAxisValueFormatter {

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
        // It is slated to be improved via #11143.
        let formattedValue = "\(value)k"

        return formattedValue
    }
}

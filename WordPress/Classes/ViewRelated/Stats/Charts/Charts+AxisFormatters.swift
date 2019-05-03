
import Foundation

import Charts

// MARK: - HorizontalAxisFormatter

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
class HorizontalAxisFormatter: IAxisValueFormatter {

    // MARK: Properties

    private let initialDateInterval: TimeInterval

    private lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")

        return formatter
    }()

    // MARK: HorizontalAxisFormatter

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

// MARK: - VerticalAxisFormatter

class VerticalAxisFormatter: IAxisValueFormatter {

    // MARK: Properties

    private lazy var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0

        return formatter
    }()

    // MARK: IAxisValueFormatter

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let formattedValue = chartAbbreviatedString(value)
        return formattedValue
    }

    /// Implementation was informed by Double.abbreviatedString(forHeroNumber:)
    ///
    private func chartAbbreviatedString(_ value: Double) -> String {
        if value < 0 {
            return "0"
        }
        if value < 1 {
            return "1"
        }

        let formatThreshold = Double(1000)
        if value < formatThreshold {
            return formatter.string(for: value) ?? "\(value)"
        }

        let exp: Int = Int(log10(value) / 3.0)
        let units: [String] = ["k", "m", "b", "t", "p", "e"]
        let roundedNum: Double = Foundation.round(10 * value / pow(1000.0, Double(exp))) / 10

        if roundedNum == 1000.0 {
            return "\(1)\(units[exp])"
        } else {
            let formatted = formatter.string(for: roundedNum) ?? "\(value)"
            return "\(formatted)\(units[exp-1])"
        }
    }
}

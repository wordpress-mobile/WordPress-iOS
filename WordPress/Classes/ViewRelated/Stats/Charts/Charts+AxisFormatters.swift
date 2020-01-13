
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
    private let period: StatsPeriodUnit
    private let periodHelper = StatsPeriodHelper()

    private lazy var formatter = DateFormatter()

    // MARK: HorizontalAxisFormatter

    init(initialDateInterval: TimeInterval, period: StatsPeriodUnit = .day) {
        self.initialDateInterval = initialDateInterval
        self.period = period
    }

    // MARK: IAxisValueFormatter

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        updateFormatterTemplate()

        let adjustedValue = initialDateInterval + (value < 0 ? 0 : value)
        let date = Date(timeIntervalSince1970: adjustedValue)

        switch period {
            case .week:
                return formattedDate(forWeekContaining: date)
            default:
                return formatter.string(from: date)
        }
    }

    private func updateFormatterTemplate() {
        formatter.setLocalizedDateFormatFromTemplate(period.dateFormatTemplate)
    }

    private func formattedDate(forWeekContaining date: Date) -> String {
        let week = periodHelper.weekIncludingDate(date)
        guard let weekStart = week?.weekStart, let weekEnd = week?.weekEnd else {
            return ""
        }

        return "\(formatter.string(from: weekStart)) to \(formatter.string(from: weekEnd))"
    }
}

// MARK: - VerticalAxisFormatter

class VerticalAxisFormatter: IAxisValueFormatter {

    // MARK: Properties

    private let largeValueFormatter = LargeValueFormatter()

    // MARK: IAxisValueFormatter

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        if value <= 0.0 {
            return "0"
        }

        return largeValueFormatter.stringForValue(value, axis: axis)
    }

    // Matches WPAndroid behavior to produce neater rounded values on
    // the vertical axis.
    static func roundUpAxisMaximum(_ input: Double) -> Double {
        if input > 100 {
            return roundUpAxisMaximum(input / 10) * 10
        } else {
            for i in 1..<25 {
                let limit = Double(4 * i)
                if input < limit {
                    return limit
                }
            }
            return Double(100)
        }
    }
}

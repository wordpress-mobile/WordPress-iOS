// Ported from https://github.com/danielgindi/Charts/ChartsDemo-iOS/Swift/Formatters/LargeValueFormatter.swift

import Foundation
import Charts

private let MAX_LENGTH = 5

@objc protocol Testing123 { }

public class LargeValueFormatter: NSObject, IValueFormatter, IAxisValueFormatter {

    /// Suffix to be appended after the values.
    ///
    /// **default**: suffixes: ["", "k", "m", "b", "t"]
    public var suffixes = ["", "k", "m", "b", "t"]

    /// An appendix text to be added at the end of the formatted value.
    public var appendix: String?

    public init(appendix: String? = nil) {
        self.appendix = appendix
    }

    fileprivate func format(value: Double) -> String {
        guard let string = LargeValueFormatter.formatter.string(from: NSNumber(value: value)) else {
            return ""
        }

        // Grab the exponent value
        let penultimateIndex = string.index(string.endIndex, offsetBy: -2)
        let exponent = string[penultimateIndex...]
        let exponentInt = Int(exponent) ?? 0

        // Replace the exponent with the correct suffix
        let replaced = string.replacingOccurrences(of: "E[0-9][0-9]", with: suffixes[exponentInt / 3], options: .regularExpression)

        return replaced
   }

    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return format(value: round(value))
    }

    public func stringForValue(
        _ value: Double,
        entry: ChartDataEntry,
        dataSetIndex: Int,
        viewPortHandler: ViewPortHandler?) -> String {
        return format(value: round(value))
    }

    private static var formatter: NumberFormatter = {
        var numberFormatter = NumberFormatter()
        // Fix the locale, as our code to replace the exponent may not function in some locales.
        numberFormatter.locale = Locale(identifier: "en-US")
        numberFormatter.positiveFormat = "###E00"
        numberFormatter.minimumFractionDigits = 1
        numberFormatter.maximumFractionDigits = 3
        return numberFormatter
    }()
}

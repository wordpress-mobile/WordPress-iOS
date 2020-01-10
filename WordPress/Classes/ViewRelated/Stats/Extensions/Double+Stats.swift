import Foundation

fileprivate struct Unit {
    let abbreviation: String
    let name: String
}

extension Double {

    private static var _numberFormatter: NumberFormatter = NumberFormatter()
    private static var _decimalFormatter: NumberFormatter = NumberFormatter()

    private var numberFormatter: NumberFormatter {
        get {
            let formatter = Double._numberFormatter
            // Add commas to value
            formatter.numberStyle = .decimal
            return formatter
        }
    }

    private var decimalFormatter: NumberFormatter {
         get {
             let formatter = Double._decimalFormatter
             // Show at least one digit after the decimal
             formatter.minimumFractionDigits = 1
             return formatter
         }
     }

    private static var _units: [Unit] {
        get {
            var unitsArray: [Unit] = []
            unitsArray.append(Unit(abbreviation: "K", name: "thousand"))
            unitsArray.append(Unit(abbreviation: "M", name: "million"))
            unitsArray.append(Unit(abbreviation: "B", name: "billion"))
            unitsArray.append(Unit(abbreviation: "T", name: "trillion"))
            unitsArray.append(Unit(abbreviation: "P", name: "quadrillion"))
            unitsArray.append(Unit(abbreviation: "E", name: "quintillion"))
            return unitsArray
        }
    }

    private var units: [Unit] {
        get {
            return Double._units
        }
    }

    /// Provides a short, friendly representation of the current Double value. If the value is
    /// below 10,000, the decimal is stripped and the string returned will look like an Int. If the value
    /// is above 10,000, the value is rounded to the nearest tenth and the appropriate abbreviation
    /// will be appended (k, m, b, t, p, e).
    ///
    /// Examples:
    ///  - 0 becomes "0"
    ///  - 9999 becomes "9999"
    ///  - 10000 becomes "10.0k"
    ///  - 987654 becomes "987.7k"
    ///  - 999999 becomes "1m"
    ///  - 1000000 becomes "1m"
    ///  - 1234324 becomes "1.2m"
    ///  - 5800199 becomes "5.8m"
    ///  - 5897459 becomes "5.9m"
    ///  - 1000000000 becomes "1b"
    ///  - 1000000000000 becomes "1t"

    func abbreviatedString(forHeroNumber: Bool = false) -> String {
        let absValue = fabs(self)
        let abbreviationLimit = forHeroNumber ? 100000.0 : 10000.0

        if absValue < abbreviationLimit {
            return self.formatWithCommas()
        }

        let exp: Int = Int(log10(absValue) / 3.0)
        let unsignedRoundedNum: Double = Foundation.round(10 * absValue / pow(1000.0, Double(exp))) / 10

        var roundedNum: Double
        var unit: Unit

        if unsignedRoundedNum == 1000.0 {
            roundedNum = 1
            unit = units[exp]
        } else {
            roundedNum = unsignedRoundedNum
            unit = units[exp-1]
        }

        roundedNum = self < 0 ? -roundedNum : roundedNum
        let formattedValue = roundedNum.formatWithFractions()

        let format = NSLocalizedString("%@%@", comment: "Label displaying abbreviated value. The first parameter is the value, the second is the unit. Ex: 55.5M, 66.6K.")
        let formattedString = String.localizedStringWithFormat(format, formattedValue, unit.abbreviation)
        formattedString.accessibilityLabel = String.localizedStringWithFormat(format, formattedValue, unit.name)

        return formattedString
    }

    private func formatWithCommas() -> String {
        return numberFormatter.string(for: self) ?? ""
    }

    private func formatWithFractions() -> String {
        return decimalFormatter.string(for: self) ?? String(self)
    }

}

extension NSNumber {
    func abbreviatedString(forHeroNumber: Bool = false) -> String {
        return self.doubleValue.abbreviatedString(forHeroNumber: forHeroNumber)
    }
}

extension Float {
    func abbreviatedString(forHeroNumber: Bool = false) -> String {
        return Double(self).abbreviatedString(forHeroNumber: forHeroNumber)
    }
}

extension Int {
    func abbreviatedString(forHeroNumber: Bool = false) -> String {
        return Double(self).abbreviatedString(forHeroNumber: forHeroNumber)
    }
}

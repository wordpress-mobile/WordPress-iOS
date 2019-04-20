import Foundation

extension Double {

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
        var num = self
        let sign = num < 0 ? "-" : ""
        num = fabs(num)

        let abbreviationLimit = forHeroNumber ? 100000.0 : 10000.0

        if num < abbreviationLimit {
            return "\(sign)\(num.formatWithCommas())"
        }

        let exp: Int = Int(log10(num) / 3.0)
        let units: [String] = ["K", "M", "B", "T", "P", "E"]
        let roundedNum: Double = Foundation.round(10 * num / pow(1000.0, Double(exp))) / 10

        if roundedNum == 1000.0 {
            return "\(sign)\(1)\(units[exp])"
        } else {
            return "\(sign)\(roundedNum)\(units[exp-1])"
        }
    }

    func formatWithCommas() -> String {
        // Add commas to number
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: self)) ?? ""
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

    func formatWithCommas() -> String {
        return Double(self).formatWithCommas()
    }
}

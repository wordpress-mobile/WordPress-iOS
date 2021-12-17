import Foundation

fileprivate struct Unit {
    let abbreviationFormat: String
    let accessibilityLabelFormat: String
}

extension Double {

    private var numberFormatter: NumberFormatter {
        get {
            struct Cache {
                static let formatter: NumberFormatter = {
                    let formatter = NumberFormatter()
                    // Add commas to value
                    formatter.numberStyle = .decimal
                    return formatter
                }()
            }

            return Cache.formatter
        }
    }

    private var decimalFormatter: NumberFormatter {
        get {
            struct Cache {
                static let formatter: NumberFormatter = {
                    let formatter = NumberFormatter()
                    // Show at least one digit after the decimal
                    formatter.minimumFractionDigits = 1
                    return formatter
                }()
            }

            return Cache.formatter
        }
    }

    private var units: [Unit] {
        get {
            struct Cache {
                static let units: [Unit] = {
                    var units: [Unit] = []
                    // Note: using `AppLocalizedString` here (instead of `NSLocalizedString`) to ensure that strings
                    // will be looked up from the app's _own_ `Localizable.strings` file, even when this file is used
                    // as part of an _App Extension_ (especially our various stats Widgets which also use this file)

                    units.append(Unit(
                        abbreviationFormat: AppLocalizedString("%@K", comment: "Label displaying value in thousands. Ex: 66.6K."),
                        accessibilityLabelFormat: AppLocalizedString("%@ thousand", comment: "Accessibility label for value in thousands. Ex: 66.6 thousand.")
                    ))

                    units.append(Unit(
                        abbreviationFormat: AppLocalizedString("%@M", comment: "Label displaying value in millions. Ex: 66.6M."),
                        accessibilityLabelFormat: AppLocalizedString("%@ million", comment: "Accessibility label for value in millions. Ex: 66.6 million.")
                    ))

                    units.append(Unit(
                        abbreviationFormat: AppLocalizedString("%@B", comment: "Label displaying value in billions. Ex: 66.6B."),
                        accessibilityLabelFormat: AppLocalizedString("%@ billion", comment: "Accessibility label for value in billions. Ex: 66.6 billion.")
                    ))

                    units.append(Unit(
                        abbreviationFormat: AppLocalizedString("%@T", comment: "Label displaying value in trillions. Ex: 66.6T."),
                        accessibilityLabelFormat: AppLocalizedString("%@ trillion", comment: "Accessibility label for value in trillions. Ex: 66.6 trillion.")
                    ))

                    units.append(Unit(
                        abbreviationFormat: AppLocalizedString("%@P", comment: "Label displaying value in quadrillions. Ex: 66.6P."),
                        accessibilityLabelFormat: AppLocalizedString("%@ quadrillion", comment: "Accessibility label for value in quadrillion. Ex: 66.6 quadrillion.")
                    ))

                    units.append(Unit(
                        abbreviationFormat: AppLocalizedString("%@E", comment: "Label displaying value in quintillions. Ex: 66.6E."),
                        accessibilityLabelFormat: AppLocalizedString("%@ quintillion", comment: "Accessibility label for value in quintillions. Ex: 66.6 quintillion.")
                    ))

                    return units
                }()
            }

            return Cache.units
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
            guard exp >= units.startIndex else {
                return self.formatWithCommas()
            }

            roundedNum = 1
            unit = units[exp]
        } else {
            let unitIndex = exp - 1

            guard unitIndex >= units.startIndex else {
                return self.formatWithCommas()
            }

            roundedNum = unsignedRoundedNum
            unit = units[unitIndex]
        }

        roundedNum = self < 0 ? -roundedNum : roundedNum
        let formattedValue = roundedNum.formatWithFractions()

        let formattedString = String.localizedStringWithFormat(unit.abbreviationFormat, formattedValue)
        formattedString.accessibilityLabel = String.localizedStringWithFormat(unit.accessibilityLabelFormat, formattedValue)

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

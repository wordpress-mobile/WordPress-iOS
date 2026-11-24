import Foundation

fileprivate struct Unit {
    let abbreviationFormat: String
    let accessibilityLabelFormat: String
}

/// A stats number abbreviated for display (e.g. "1.2M"), paired with its spoken form for
/// VoiceOver (e.g. "1.2 million").
public struct AbbreviatedNumber: Equatable, Sendable {
    public let text: String
    public let accessibilityLabel: String
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

    private var spokenDecimalFormatter: NumberFormatter {
        get {
            struct Cache {
                static let formatter: NumberFormatter = {
                    let formatter = NumberFormatter()
                    // Drop a trailing ".0" so VoiceOver doesn't read "one point zero million"
                    formatter.minimumFractionDigits = 0
                    formatter.maximumFractionDigits = 1
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
    /// will be appended (K, M, B, T, P, E).
    ///
    /// Examples (en_US):
    ///  - 0 becomes "0"
    ///  - 9999 becomes "9,999"
    ///  - 10000 becomes "10.0K"
    ///  - 987654 becomes "987.7K"
    ///  - 999999 becomes "1.0M"
    ///  - 1000000 becomes "1.0M"
    ///  - 1234324 becomes "1.2M"
    ///  - 5800199 becomes "5.8M"
    ///  - 5897459 becomes "5.9M"
    ///  - 1000000000 becomes "1.0B"
    ///  - 1000000000000 becomes "1.0T"
    public func abbreviatedString(forHeroNumber: Bool = false) -> String {
        abbreviated(forHeroNumber: forHeroNumber).text
    }

    /// The spoken equivalent of `abbreviatedString(forHeroNumber:)` for VoiceOver.
    ///
    /// Below the abbreviation limit it returns the comma-formatted number; above it, the
    /// unit spelled out without a trailing ".0" (e.g. "1.2 million" instead of "1.2M", and
    /// "1 million" instead of "1.0M").
    public func abbreviatedAccessibilityLabel(forHeroNumber: Bool = false) -> String {
        abbreviated(forHeroNumber: forHeroNumber).accessibilityLabel
    }

    /// The displayed and spoken representations from a single rounding pass. Prefer this when a
    /// view needs both, so the two can't disagree.
    public func abbreviated(forHeroNumber: Bool = false) -> AbbreviatedNumber {
        guard let abbreviation = abbreviation(forHeroNumber: forHeroNumber) else {
            let formatted = formatWithCommas()
            return AbbreviatedNumber(text: formatted, accessibilityLabel: formatted)
        }
        let (value, unit) = abbreviation
        return AbbreviatedNumber(
            text: String.localizedStringWithFormat(unit.abbreviationFormat, value.formatWithFractions()),
            accessibilityLabel: String.localizedStringWithFormat(unit.accessibilityLabelFormat, value.formatForSpeech())
        )
    }

    /// Shared rounding and unit selection for the abbreviated representations.
    ///
    /// Returns `nil` when the value should be shown in full (below the limit, not finite, or outside
    /// the supported units), in which case callers fall back to `formatWithCommas()`.
    private func abbreviation(forHeroNumber: Bool) -> (value: Double, unit: Unit)? {
        let absValue = fabs(self)
        let abbreviationLimit = forHeroNumber ? 100000.0 : 10000.0

        // `Int(_:)` traps on NaN and infinity
        guard absValue.isFinite, absValue >= abbreviationLimit else {
            return nil
        }

        let exp = Int(log10(absValue) / 3.0)
        let unsignedRoundedNum: Double = Foundation.round(10 * absValue / pow(1000.0, Double(exp))) / 10

        // A value that rounds up to 1000 moves into the next unit (999,999 is "1.0M", not "1000.0K")
        let roundsUp = unsignedRoundedNum == 1000.0
        let unitIndex = roundsUp ? exp : exp - 1

        guard units.indices.contains(unitIndex) else {
            return nil
        }

        let roundedNum = roundsUp ? 1 : unsignedRoundedNum
        return (self < 0 ? -roundedNum : roundedNum, units[unitIndex])
    }

    public func percentageString() -> String {
        return NumberFormatter.statsPercentage.string(from: .init(value: self))!
    }

    private func formatWithCommas() -> String {
        return numberFormatter.string(for: self) ?? ""
    }

    private func formatWithFractions() -> String {
        return decimalFormatter.string(for: self) ?? String(self)
    }

    private func formatForSpeech() -> String {
        return spokenDecimalFormatter.string(for: self) ?? String(self)
    }
}

extension Int {
    public func abbreviatedString(forHeroNumber: Bool = false) -> String {
        Double(self).abbreviatedString(forHeroNumber: forHeroNumber)
    }

    public func abbreviatedAccessibilityLabel(forHeroNumber: Bool = false) -> String {
        Double(self).abbreviatedAccessibilityLabel(forHeroNumber: forHeroNumber)
    }

    public func abbreviated(forHeroNumber: Bool = false) -> AbbreviatedNumber {
        Double(self).abbreviated(forHeroNumber: forHeroNumber)
    }

    public func percentageString() -> String {
        Double(self).percentageString()
    }
}

private extension NumberFormatter {
    static let statsPercentage: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.multiplier = 1
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        if let preferredLocaleIdentifier = Bundle.main.preferredLocalizations.first {
            formatter.locale = Locale(identifier: preferredLocaleIdentifier)
        } else {
            formatter.locale = Locale.current
        }

        return formatter
    }()
}

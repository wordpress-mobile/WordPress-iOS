import Foundation

extension NumberFormatter {
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

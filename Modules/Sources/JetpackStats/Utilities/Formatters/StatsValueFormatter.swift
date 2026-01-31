import Foundation

/// Protocol for value formatters that can format metric values.
protocol ValueFormatterProtocol {
    func format(value: Int, context: StatsValueFormatter.Context) -> String
}

/// Formats site metric values for display based on the metric type and context.
///
/// Example usage:
/// ```swift
/// let formatter = StatsValueFormatter(metric: .timeOnSite)
/// formatter.format(value: 90) // "1m 30s"
/// formatter.format(value: 90, context: .compact) // "1m"
///
/// let viewsFormatter = StatsValueFormatter(metric: .views)
/// viewsFormatter.format(value: 15789) // "15,789"
/// viewsFormatter.format(value: 15789, context: .compact) // "16K"
/// ```
struct StatsValueFormatter: ValueFormatterProtocol {
    enum Context {
        case regular
        case compact
    }

    let metric: SiteMetric

    init(metric: SiteMetric) {
        self.metric = metric
    }

    func format(value: Int, context: Context = .regular) -> String {
        switch metric {
        case .timeOnSite:
            let minutes = value / 60
            let seconds = value % 60
            if minutes > 0 {
                switch context {
                case .regular:
                    return "\(minutes)m \(seconds)s"
                case .compact:
                    return "\(minutes)m"
                }
            } else {
                return "\(seconds)s"
            }
        case .bounceRate:
            return "\(value)%"
        default:
            return Self.formatNumber(value, onlyLarge: context == .regular)
        }
    }

    /// Formats a number with appropriate abbreviations for large values.
    ///
    /// - Parameters:
    ///   - value: The number to format
    ///   - onlyLarge: If true, only abbreviates numbers >= 10,000
    /// - Returns: A formatted string (e.g., "1.2K", "1.5M")
    ///
    /// Example:
    /// ```swift
    /// StatsValueFormatter.formatNumber(1234) // "1.2K"
    /// StatsValueFormatter.formatNumber(1234, onlyLarge: true) // "1,234"
    /// StatsValueFormatter.formatNumber(15789) // "16K"
    /// ```
    static func formatNumber(_ value: Int, onlyLarge: Bool = false) -> String {
        if onlyLarge && abs(value) < 10_000 {
            return value.formatted(.number)
        }
        return value.formatted(.number.notation(.compactName))
    }

    /// Calculates the percentage change between two values.
    ///
    /// - Parameters:
    ///   - current: The current value
    ///   - previous: The previous value to compare against
    /// - Returns: The percentage change as a decimal (0.5 = 50% increase, -0.5 = 50% decrease)
    ///
    /// Example:
    /// ```swift
    /// let formatter = StatsValueFormatter(metric: .views)
    /// formatter.percentageChange(current: 150, previous: 100) // 0.5 (50% increase)
    /// formatter.percentageChange(current: 50, previous: 100) // -0.5 (50% decrease)
    /// ```
    func percentageChange(current: Int, previous: Int) -> Double {
        guard previous > 0 else { return 0 }
        return Double(current - previous) / Double(previous)
    }
}

/// Formats WordAds metric values for display based on the metric type and context.
struct WordAdsValueFormatter: ValueFormatterProtocol {
    let metric: WordAdsMetric

    init(metric: WordAdsMetric) {
        self.metric = metric
    }

    func format(value: Int, context: StatsValueFormatter.Context = .regular) -> String {
        switch metric.id {
        case "revenue":
            let dollars = Double(value) / 100.0
            return dollars.formatted(.currency(code: "USD"))
        case "cpm":
            let cpm = Double(value) / 100.0
            return String(format: "$%.2f", cpm)
        case "impressions":
            return StatsValueFormatter.formatNumber(value, onlyLarge: context == .regular)
        default:
            return StatsValueFormatter.formatNumber(value, onlyLarge: context == .regular)
        }
    }

    func percentageChange(current: Int, previous: Int) -> Double {
        guard previous > 0 else { return 0 }
        return Double(current - previous) / Double(previous)
    }
}

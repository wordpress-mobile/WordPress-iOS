import Foundation
import SwiftUI

/// Represents a change from the current to the previous value and determines
/// a trend: is it a positive change, what's the percentage, etc.
struct TrendViewModel: Hashable {
    let currentValue: Int
    let previousValue: Int
    let metric: SiteMetric
    var context: StatsValueFormatter.Context = .compact

    /// The sign prefix for the change value.
    var sign: String {
        currentValue >= previousValue ? "+" : "-"
    }

    var iconSign: String {
        currentValue >= previousValue ? "↗" : "↘"
    }

    /// SF Symbol name representing the trend direction
    var systemImage: String {
        guard currentValue != previousValue else {
            return "arrow.up.and.down"
        }
        return currentValue >= previousValue ? "arrow.up.forward" : "arrow.down.forward"
    }

    /// The perceived quality of the change based on metric type.
    var sentiment: TrendSentiment {
        if currentValue == previousValue {
            return .neutral
        }
        let sentiment: TrendSentiment = currentValue >= previousValue ? .positive : .negative
        return metric.isHigherValueBetter ? sentiment : sentiment.reversed()
    }

    /// The percentage change between periods (nil if the previous value was 0).
    /// - Example: 0.5 for 50% increase, 0.25 for 25% decrease
    var percentage: Decimal? {
        guard previousValue != 0 else {
            return nil
        }
        return Decimal(abs(currentValue - previousValue)) / Decimal(abs(previousValue))
    }

    // MARK: Formatting

    /// A completed formatted trend with the absolute change and the percentage change.
    var formattedTrend: String {
        "\(formattedChange) (\(formattedPercentage))"
    }

    /// A completed formatted trend with the absolute change and the percentage change.
    var formattedTrendShort: String {
        "\(iconSign) \(formattedPercentage)  \(formattedChange)"
    }

    /// A completed formatted trend with the absolute change and the percentage change.
    var formattedTrendShort2: String {
        "\(formattedChange)   \(iconSign) \(formattedPercentage)"
    }

    /// Formatted string showing the absolute change with sign.
    /// - Example: "+1.2K" for 1,200 increase, "-500" for 500 decrease.
    var formattedChange: String {
        "\(sign)\(formattedChangeNoSign)"
    }

    var formattedChangeNoSign: String {
        formattedValue(abs(currentValue - previousValue))
    }

    var formattedCurrentValue: String {
        formattedValue(currentValue)
    }

    var formattedPreviousValue: String {
        formattedValue(previousValue)
    }

    private func formattedValue(_ value: Int) -> String {
        StatsValueFormatter(metric: metric)
            .format(value: value, context: context)
    }

    /// Formatted percentage string (shows "∞" for infinite change)
    /// - Example: "25%", "150.5%", or "∞" when previousValue was 0.
    var formattedPercentage: String {
        if currentValue == 0 && previousValue == 0 {
            return "0"
        }
        guard let percentage else {
            return "∞"
        }
        return percentage.formatted(
            .percent
            .notation(.compactName)
            .precision(.fractionLength(0...1))
        )
    }
}

extension TrendViewModel {
    static func make(_ chartData: ChartData, context: StatsValueFormatter.Context = .compact) -> TrendViewModel {
        TrendViewModel(
            currentValue: chartData.currentTotal,
            previousValue: chartData.previousTotal,
            metric: chartData.metric,
            context: context
        )
    }
}

/// The change can be percieved as either positive or negative depending on
/// the data type. For example, growth in "Views" is positive but grown in
/// "Bounce Rate" is negative.
enum TrendSentiment {
    /// No change.
    case neutral
    /// The change in the value is positive (e.g. "more views", or "lower bounce rate").
    case positive
    case negative

    var foregroundColor: Color {
        switch self {
        case .neutral: Color.secondary
        case .positive: Constants.Colors.positiveChangeForeground
        case .negative: Constants.Colors.negativeChangeForeground
        }
    }

    var backgroundColor: Color {
        switch self {
        case .neutral: Color(UIColor(light: .secondarySystemBackground, dark: .tertiarySystemBackground))
        case .positive: Constants.Colors.positiveChangeBackground
        case .negative: Constants.Colors.negativeChangeBackground
        }
    }

    /// Returns the opposite sentiment (for metrics where lower is better)
    func reversed() -> TrendSentiment {
        switch self {
        case .neutral: .neutral
        case .positive: .negative
        case .negative: .positive
        }
    }
}

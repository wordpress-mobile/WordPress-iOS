import SwiftUI

struct ChartAxisDateLabel: View {
    let date: Date
    let granularity: DateRangeGranularity

    @Environment(\.context) var context

    var body: some View {
        Group {
            if granularity == .hour {
                hourLabel
            } else {
                standardLabel
            }
        }
        .fixedSize() // Prevent from clipping (sometimes happens)
    }

    private var standardLabel: some View {
        Text(context.formatters.date.formatDate(date, granularity: granularity))
            .font(.caption2.weight(.medium))
            .foregroundColor(.secondary)
    }

    @ViewBuilder
    private var hourLabel: some View {
        let formatted = context.formatters.date.formatDate(date, granularity: granularity)

        if let (time, period) = parseHourFormat(formatted) {
            (Text(time.uppercased())
                .font(.caption2.weight(.medium))
             + Text(period.lowercased())
                .font(.caption2.weight(.medium).lowercaseSmallCaps()))
                .foregroundColor(.secondary)
        } else {
            standardLabel
        }
    }

    /// Parses hour format string into time and period components
    /// - Parameter formatted: The formatted date string (e.g., "1 PM", "12 AM")
    /// - Returns: A tuple of (time, period) if successfully parsed, nil otherwise
    private func parseHourFormat(_ formatted: String) -> (time: String, period: String)? {
        let components = formatted.split(separator: " ")
        guard components.count == 2 else { return nil }

        return (String(components[0]), String(components[1]))
    }
}

#Preview {
    VStack(spacing: 20) {
        // Hour format
        ChartAxisDateLabel(date: Date(), granularity: .hour)

        // Day format
        ChartAxisDateLabel(date: Date(), granularity: .day)

        // Month format
        ChartAxisDateLabel(date: Date(), granularity: .month)
    }
    .padding()
}

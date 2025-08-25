import SwiftUI

struct CountryTooltip: View {
    let countryCode: String
    let location: TopListItem.Location?
    let previousLocation: TopListItem.Location?
    let primaryColor: Color

    private var countryName: String {
        if let location {
            return location.country
        } else {
            // Use native API to get country name from code
            let locale = Locale.current
            return locale.localizedString(forRegionCode: countryCode) ?? countryCode
        }
    }

    private var countryFlag: String {
        if let flag = location?.flag {
            return flag
        } else {
            // Generate flag emoji from country code
            let base: UInt32 = 127397
            var s = ""
            for scalar in countryCode.uppercased().unicodeScalars {
                s.unicodeScalars.append(UnicodeScalar(base + scalar.value)!)
            }
            return s
        }
    }

    private var trend: TrendViewModel? {
        guard let currentViews = location?.metrics.views,
              let previousViews = previousLocation?.metrics.views,
              previousViews > 0 else {
            return nil
        }
        return TrendViewModel(
            currentValue: currentViews,
            previousValue: previousViews,
            metric: .views
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Country header
            HStack(spacing: 6) {
                Text(countryFlag)
                    .font(.title3)
                Text(countryName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            if let location {
                // Current views
                CountryTooltipRow(
                    color: primaryColor,
                    value: location.metrics.views,
                    isPrimary: true
                )

                // Previous views
                if let previousLocation {
                    CountryTooltipRow(
                        color: Color.secondary,
                        value: previousLocation.metrics.views,
                        isPrimary: false
                    )
                }

                // Trend
                if let trend {
                    Text(trend.formattedTrendShort)
                        .contentTransition(.numericText())
                        .font(.subheadline.weight(.medium)).tracking(-0.33)
                        .foregroundColor(trend.sentiment.foregroundColor)
                }
            } else {
                // No data available
                Text(Strings.Countries.noViews)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .fixedSize()
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Constants.Colors.shadowColor, radius: 4, x: 0, y: 2)
    }
}

private struct CountryTooltipRow: View {
    let color: Color
    let value: Int?
    let isPrimary: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(formattedValue)
                .font(.subheadline)
                .fontWeight(isPrimary ? .medium : .regular)
                .foregroundColor(isPrimary ? .primary : .secondary)
        }
    }

    private var formattedValue: String {
        guard let value else {
            return "–"
        }
        return StatsValueFormatter(metric: .views)
            .format(value: value)
    }
}

#Preview {
    VStack(spacing: 20) {
        // With data
        CountryTooltip(
            countryCode: "US",
            location: TopListItem.Location(
                country: "United States",
                flag: "🇺🇸",
                countryCode: "US",
                metrics: SiteMetricsSet(views: 15000)
            ),
            previousLocation: TopListItem.Location(
                country: "United States",
                flag: "🇺🇸",
                countryCode: "US",
                metrics: SiteMetricsSet(views: 12000)
            ),
            primaryColor: Color.blue
        )

        // Without data
        CountryTooltip(
            countryCode: "XX",
            location: nil,
            previousLocation: nil,
            primaryColor: Color.blue
        )
    }
    .padding()
    .background(Color(.secondarySystemBackground))
}

import SwiftUI

struct CountriesMapView: View {
    let data: CountriesMapData
    let primaryColor: Color
    @Binding var selectedCountryCode: String?

    var body: some View {
        InteractiveMapView(
            data: data.mapDataAsDouble,
            configuration: InteractiveMapView.Configuration(tintColor: UIColor(primaryColor)),
            selectedCountryCode: $selectedCountryCode
        )
    }
}

struct CountriesMapData {
    let minViewsCount: Int
    let maxViewsCount: Int
    let mapData: [String: NSNumber]
    let locations: [TopListData.Location]
    let previousLocations: [String: TopListData.Location]

    var mapDataAsDouble: [String: Double] {
        mapData.mapValues { $0.doubleValue }
    }

    func location(for countryCode: String) -> TopListData.Location? {
        locations.first { $0.countryCode == countryCode }
    }

    func previousLocation(for countryCode: String) -> TopListData.Location? {
        previousLocations[countryCode]
    }

    init(locations: [TopListData.Location], previousLocations: [TopListData.Location] = []) {
        self.locations = locations
        self.previousLocations = Dictionary(
            uniqueKeysWithValues: previousLocations.compactMap { location in
                guard let code = location.countryCode else { return nil }
                return (code, location)
            }
        )

        let sortedLocations = locations.sorted { ($0.metrics.views ?? 0) > ($1.metrics.views ?? 0) }

        self.minViewsCount = sortedLocations.last?.metrics.views ?? 0
        self.maxViewsCount = sortedLocations.first?.metrics.views ?? 0

        self.mapData = locations.reduce(into: [String: NSNumber]()) { result, location in
            if let countryCode = location.countryCode,
               let views = location.metrics.views {
                result[countryCode] = NSNumber(value: views)
            }
        }
    }
}

struct CountriesMapContainer: View {
    let data: CountriesMapData
    let primaryColor: Color

    @ScaledMetric private var mapHeight = 200
    @State private var selectedCountryCode: String?

    var body: some View {
        VStack(spacing: 12) {
            // Map View with tooltip overlay
            ZStack(alignment: .top) {
                CountriesMapView(data: data, primaryColor: primaryColor, selectedCountryCode: $selectedCountryCode)
                    .frame(height: mapHeight)
                    .cornerRadius(8)

                // Tooltip positioned near the top center
                if let countryCode = selectedCountryCode {
                    CountryTooltip(
                        countryCode: countryCode,
                        location: data.location(for: countryCode),
                        previousLocation: data.previousLocation(for: countryCode),
                        primaryColor: primaryColor
                    )
                    .padding(.top, 16)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: selectedCountryCode)
                }
            }

            // Gradient Legend
            HStack(spacing: 0) {
                Text(data.minViewsCount.abbreviatedString())
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Spacer()

                LinearGradient(
                    colors: [primaryColor.opacity(0.1), primaryColor],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 10)
                .cornerRadius(5)

                Spacer()

                Text(data.maxViewsCount.abbreviatedString())
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Views range from \(data.minViewsCount) to \(data.maxViewsCount)")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("World map showing views by country")
    }
}

private extension Int {
    func abbreviatedString() -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1

        if self >= 1_000_000 {
            return "\(formatter.string(from: NSNumber(value: Double(self) / 1_000_000)) ?? "0")M"
        } else if self >= 1_000 {
            return "\(formatter.string(from: NSNumber(value: Double(self) / 1_000)) ?? "0")K"
        } else {
            return "\(self)"
        }
    }
}

#Preview {
    CountriesMapContainer(
        data: CountriesMapData(locations: [
            TopListData.Location(
                country: "United States",
                flag: "🇺🇸",
                countryCode: "US",
                metrics: SiteMetricsSet(views: 10000)
            ),
            TopListData.Location(
                country: "United Kingdom",
                flag: "🇬🇧",
                countryCode: "GB",
                metrics: SiteMetricsSet(views: 4000)
            ),
            TopListData.Location(
                country: "Canada",
                flag: "🇨🇦",
                countryCode: "CA",
                metrics: SiteMetricsSet(views: 2800)
            ),
            TopListData.Location(
                country: "Germany",
                flag: "🇩🇪",
                countryCode: "DE",
                metrics: SiteMetricsSet(views: 2000)
            ),
            TopListData.Location(
                country: "Australia",
                flag: "🇦🇺",
                countryCode: "AU",
                metrics: SiteMetricsSet(views: 1600)
            ),
            TopListData.Location(
                country: "France",
                flag: "🇫🇷",
                countryCode: "FR",
                metrics: SiteMetricsSet(views: 1400)
            ),
            TopListData.Location(
                country: "Japan",
                flag: "🇯🇵",
                countryCode: "JP",
                metrics: SiteMetricsSet(views: 1100)
            ),
            TopListData.Location(
                country: "Netherlands",
                flag: "🇳🇱",
                countryCode: "NL",
                metrics: SiteMetricsSet(views: 800)
            )
        ]),
        primaryColor: Constants.Colors.blue
    )
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(UIColor(light: .systemBackground, dark: .secondarySystemBackground)))
}

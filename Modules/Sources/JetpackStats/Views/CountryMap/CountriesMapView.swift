import SwiftUI

struct CountriesMapView: View {
    let data: CountriesMapData
    let primaryColor: UIColor

    private let mapHeight: CGFloat = 240
    @State private var selectedCountryCode: String?

    var body: some View {
        VStack(spacing: 12) {
            // Map View with tooltip overlay
            ZStack(alignment: .top) {
                InteractiveMapView(
                    data: data.mapData,
                    configuration: .init(tintColor: primaryColor),
                    selectedCountryCode: $selectedCountryCode
                )
                .frame(height: mapHeight)
            }

            // Gradient Legend
            HStack(spacing: 4) {
                Text(formattedValue(data.minViews))
                    .font(.footnote)
                    .foregroundColor(.secondary)

                LinearGradient(
                    colors: [Color(primaryColor.lightened(by: 0.8)), Color(primaryColor)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 60, height: 8)
                .cornerRadius(5)

                Text(formattedValue(data.maxViews))
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Spacer()
            }
        }
        .overlay(alignment: .top) {
            // Tooltip positioned near the top center
            if let countryCode = selectedCountryCode {
                CountryTooltip(
                    countryCode: countryCode,
                    location: data.location(for: countryCode),
                    previousLocation: data.previousLocation(for: countryCode),
                    primaryColor: Color(primaryColor)
                )
                .transition(.opacity)
                .padding(.top, -24)
                .animation(.easeInOut(duration: 0.2), value: selectedCountryCode)
            }
        }
    }

    private func formattedValue(_ value: Int) -> String {
        StatsValueFormatter(metric: data.metric)
            .format(value: value, context: .compact)
    }
}

struct CountriesMapData {
    let metric: SiteMetric
    let minViews: Int
    let maxViews: Int
    let mapData: [String: Int]
    let locations: [TopListData.Location]
    let previousLocations: [String: TopListData.Location]

    func location(for countryCode: String) -> TopListData.Location? {
        locations.first { $0.countryCode == countryCode }
    }

    func previousLocation(for countryCode: String) -> TopListData.Location? {
        previousLocations[countryCode]
    }

    init(
        metric: SiteMetric,
        locations: [TopListData.Location],
        previousLocations: [TopListItemID: TopListData.Location] = [:]
    ) {
        self.metric = metric
        self.locations = locations
        self.previousLocations = {
            var output: [String: TopListData.Location] = [:]
            for location in previousLocations.values {
                if let countryCode = location.countryCode {
                    output[countryCode] = location
                }
            }
            return output
        }()

        let views = locations.compactMap(\.metrics.views)
        self.minViews = views.min() ?? 0
        self.maxViews = views.max() ?? 0

        self.mapData = {
            var output: [String: Int] = [:]
            for location in locations {
                if let countryCode = location.countryCode,
                   let views = location.metrics.views {
                    output[countryCode] = views
                }
            }
            return output
        }()
    }
}

#Preview {
    CountriesMapView(
        data: CountriesMapData(metric: .views, locations: [
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
        primaryColor: Constants.Colors.uiColorBlue
    )
    .padding()
    .cardStyle()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(UIColor(light: .secondarySystemBackground, dark: .systemBackground)))
}

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
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
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

#Preview {
    CountriesMapView(
        data: CountriesMapData(metric: .views, locations: [
            TopListItem.Location(
                country: "United States",
                flag: "🇺🇸",
                countryCode: "US",
                metrics: SiteMetricsSet(views: 10000)
            ),
            TopListItem.Location(
                country: "United Kingdom",
                flag: "🇬🇧",
                countryCode: "GB",
                metrics: SiteMetricsSet(views: 4000)
            ),
            TopListItem.Location(
                country: "Canada",
                flag: "🇨🇦",
                countryCode: "CA",
                metrics: SiteMetricsSet(views: 2800)
            ),
            TopListItem.Location(
                country: "Germany",
                flag: "🇩🇪",
                countryCode: "DE",
                metrics: SiteMetricsSet(views: 2000)
            ),
            TopListItem.Location(
                country: "Australia",
                flag: "🇦🇺",
                countryCode: "AU",
                metrics: SiteMetricsSet(views: 1600)
            ),
            TopListItem.Location(
                country: "France",
                flag: "🇫🇷",
                countryCode: "FR",
                metrics: SiteMetricsSet(views: 1400)
            ),
            TopListItem.Location(
                country: "Japan",
                flag: "🇯🇵",
                countryCode: "JP",
                metrics: SiteMetricsSet(views: 1100)
            ),
            TopListItem.Location(
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

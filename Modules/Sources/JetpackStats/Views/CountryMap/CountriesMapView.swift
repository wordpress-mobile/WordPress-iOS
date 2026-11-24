import SwiftUI

struct CountriesMapView: View {
    let data: CountriesMapData
    let primaryColor: UIColor

    private let mapHeight: CGFloat = 240
    @State private var selectedCountryCode: String?

    /// The map renders in a `WKWebView`, and building one spawns a WebContent process.
    /// Opening Stats paid for that even though this card sits well below the fold, so the
    /// web view is built the first time the map scrolls into view and kept from then on.
    /// The placeholder reserves the map's exact height, so the card lays out the same
    /// either way.
    ///
    /// This relies on the view being inside a `ScrollView`; outside one the map never
    /// becomes visible to SwiftUI and so is never built.
    @State private var isMapBuilt = false

    var body: some View {
        VStack(spacing: 12) {
            // Map View with tooltip overlay
            ZStack(alignment: .top) {
                if isMapBuilt {
                    InteractiveMapView(
                        data: data.mapData,
                        configuration: .init(tintColor: primaryColor),
                        selectedCountryCode: $selectedCountryCode
                    )
                }
            }
            .frame(height: mapHeight)
            .onScrollVisibilityChange(threshold: 0.01) { isVisible in
                if isVisible {
                    isMapBuilt = true
                }
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
    // The map is only built once it scrolls into view, so the preview needs a scroll view.
    ScrollView {
        CountriesMapView(
            data: CountriesMapData(metric: .views, locations: [
                TopListItem.Location(
                    name: "United States",
                    flag: "🇺🇸",
                    countryCode: "US",
                    metrics: SiteMetricsSet(views: 10000)
                ),
                TopListItem.Location(
                    name: "United Kingdom",
                    flag: "🇬🇧",
                    countryCode: "GB",
                    metrics: SiteMetricsSet(views: 4000)
                ),
                TopListItem.Location(
                    name: "Canada",
                    flag: "🇨🇦",
                    countryCode: "CA",
                    metrics: SiteMetricsSet(views: 2800)
                ),
                TopListItem.Location(
                    name: "Germany",
                    flag: "🇩🇪",
                    countryCode: "DE",
                    metrics: SiteMetricsSet(views: 2000)
                ),
                TopListItem.Location(
                    name: "Australia",
                    flag: "🇦🇺",
                    countryCode: "AU",
                    metrics: SiteMetricsSet(views: 1600)
                ),
                TopListItem.Location(
                    name: "France",
                    flag: "🇫🇷",
                    countryCode: "FR",
                    metrics: SiteMetricsSet(views: 1400)
                ),
                TopListItem.Location(
                    name: "Japan",
                    flag: "🇯🇵",
                    countryCode: "JP",
                    metrics: SiteMetricsSet(views: 1100)
                ),
                TopListItem.Location(
                    name: "Netherlands",
                    flag: "🇳🇱",
                    countryCode: "NL",
                    metrics: SiteMetricsSet(views: 800)
                )
            ]),
            primaryColor: Constants.Colors.uiColorBlue
        )
        .padding()
        .cardStyle()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(UIColor(light: .secondarySystemBackground, dark: .systemBackground)))
}

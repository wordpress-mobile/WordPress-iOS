import Foundation

struct CountriesMapData {
    let metric: SiteMetric
    let minViews: Int
    let maxViews: Int
    let mapData: [String: Int]
    let locations: [TopListItem.Location]
    let previousLocations: [String: TopListItem.Location]

    func location(for countryCode: String) -> TopListItem.Location? {
        locations.first { $0.countryCode == countryCode }
    }

    func previousLocation(for countryCode: String) -> TopListItem.Location? {
        previousLocations[countryCode]
    }

    init(
        metric: SiteMetric,
        locations: [TopListItem.Location],
        previousLocations: [TopListItemID: TopListItem.Location] = [:]
    ) {
        self.metric = metric
        self.locations = locations
        self.previousLocations = {
            var output: [String: TopListItem.Location] = [:]
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

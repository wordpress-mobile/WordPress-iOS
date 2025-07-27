import Foundation

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

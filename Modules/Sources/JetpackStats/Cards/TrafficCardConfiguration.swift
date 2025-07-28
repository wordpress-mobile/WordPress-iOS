import Foundation

struct TrafficCardConfiguration: Codable {
    var cards: [Card]

    enum Card: Codable {
        case chart(ChartParameters)
        case topList(TopListParameters)
    }

    struct ChartParameters: Codable {
        let metrics: [SiteMetric]
    }

    struct TopListParameters: Codable {
        let item: TopListItemType
        let metric: SiteMetric
    }
}

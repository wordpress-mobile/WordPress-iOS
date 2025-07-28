import Foundation

struct TrafficCardConfiguration: Codable {
    var cards: [Card]

    enum Card: Codable {
        case chart
        case topList(TopListParameters)
    }

    struct TopListParameters: Codable {
        let item: TopListItemType
        let metric: SiteMetric
    }

    static let defaultConfiguration = TrafficCardConfiguration(cards: [
        .chart,
        .topList(TopListParameters(item: .postsAndPages, metric: .views)),
        .topList(TopListParameters(item: .referrers, metric: .views)),
        .topList(TopListParameters(item: .locations, metric: .views))
    ])
}

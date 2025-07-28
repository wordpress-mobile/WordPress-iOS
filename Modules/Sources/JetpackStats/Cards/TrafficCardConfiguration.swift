import Foundation

struct TrafficCardConfiguration: Codable {
    var cards: [Card]

    enum Card: Codable {
        case chart(ChartParameters)
        case topList(TopListParameters)
        
        var id: UUID {
            switch self {
            case .chart(let params):
                return params.id
            case .topList(let params):
                return params.id
            }
        }
    }

    struct ChartParameters: Codable {
        let id: UUID
        let metrics: [SiteMetric]
        
        init(id: UUID = UUID(), metrics: [SiteMetric]) {
            self.id = id
            self.metrics = metrics
        }
    }

    struct TopListParameters: Codable {
        let id: UUID
        let item: TopListItemType
        let metric: SiteMetric
        
        init(id: UUID = UUID(), item: TopListItemType, metric: SiteMetric) {
            self.id = id
            self.item = item
            self.metric = metric
        }
    }
}

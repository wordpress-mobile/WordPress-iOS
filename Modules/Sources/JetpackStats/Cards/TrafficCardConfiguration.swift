import Foundation

struct TrafficCardConfiguration: Codable {
    var cards: [Card]

    enum Card: Codable {
        case chart(ChartCardConfiguration)
        case topList(TopListCardConfiguration)

        var id: UUID {
            switch self {
            case .chart(let config):
                return config.id
            case .topList(let config):
                return config.id
            }
        }
    }
}

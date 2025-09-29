import Foundation
import SwiftUI

struct TrafficCardConfiguration: Codable {
    var cards: [Card]

    enum Card: Codable {
        case today(TodayCardConfiguration)
        case chart(ChartCardConfiguration)
        case topList(TopListCardConfiguration)

        var id: UUID {
            switch self {
            case .today(let config): config.id
            case .chart(let config): config.id
            case .topList(let config): config.id
            }
        }

        var type: CardType {
            switch self {
            case .today: .today
            case .chart: .chart
            case .topList: .topList
            }
        }
    }
}

enum CardType: String, CaseIterable, Identifiable {
    case chart = "chart"
    case topList = "top_list"
    case today = "today"

    var id: CardType { self }

    var systemImage: String {
        switch self {
        case .today: "sun.horizon"
        case .chart: "chart.line.uptrend.xyaxis"
        case .topList: "list.number"
        }
    }

    var localizedTitle: String {
        switch self {
        case .chart: Strings.Cards.chart
        case .topList: Strings.Cards.topList
        case .today: Strings.Cards.today
        }
    }

    var localizedDescription: String {
        switch self {
        case .chart: Strings.Cards.chartDescription
        case .topList: Strings.Cards.topListDescription
        case .today: Strings.Cards.todayDescription
        }
    }

    var tint: Color {
        switch self {
        case .chart: Constants.Colors.blue
        case .topList: Constants.Colors.purple
        case .today: Constants.Colors.orange
        }
    }
}

import Foundation

@MainActor
protocol TrafficCardViewModel: AnyObject {
    var id: UUID { get }
    var cardType: CardType { get }
    var dateRange: StatsDateRange { get set }
    var isEditing: Bool { get set }
    var isEditable: Bool { get }
    var configurationDelegate: CardConfigurationDelegate? { get set }
}

extension TrafficCardViewModel {
    var isEditable: Bool { true }
}

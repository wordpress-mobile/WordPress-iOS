import Foundation

@MainActor
protocol TrafficCardViewModel: AnyObject {
    var id: UUID { get }
    var dateRange: StatsDateRange { get set }
    var isEditing: Bool { get set }
    var configurationDelegate: CardConfigurationDelegate? { get set }
}

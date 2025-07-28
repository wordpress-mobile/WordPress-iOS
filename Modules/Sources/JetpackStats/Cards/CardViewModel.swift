import Foundation

@MainActor
protocol TrafficCardViewModel: AnyObject {
    var id: UUID { get }
    var dateRange: StatsDateRange { get set }
}

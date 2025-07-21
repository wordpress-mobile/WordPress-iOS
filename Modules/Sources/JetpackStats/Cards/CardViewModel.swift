import Foundation

@MainActor
protocol TrafficCardViewModel: AnyObject {
    var dateRange: StatsDateRange { get set }
}

extension TrafficCardViewModel {
    nonisolated var id: ObjectIdentifier {
        ObjectIdentifier(self)
    }
}

import Foundation

/// Represents a section in the Dashboard Collection View
class DashboardCardSection: Hashable {
    let id: DashboardCard

    init(id: DashboardCard) {
        self.id = id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DashboardCardSection, rhs: DashboardCardSection) -> Bool {
        lhs.id == rhs.id
    }
}

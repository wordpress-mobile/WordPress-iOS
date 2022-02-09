import Foundation

/// Represents a card in the dashboard collection view
class DashboardCardModel: Hashable {
    let id: DashboardCard
    let cellViewModel: NSDictionary?

    init(id: DashboardCard, cellViewModel: NSDictionary? = nil) {
        self.id = id
        self.cellViewModel = cellViewModel
    }

    static func == (lhs: DashboardCardModel, rhs: DashboardCardModel) -> Bool {
        lhs.cellViewModel == rhs.cellViewModel
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(cellViewModel)
    }
}

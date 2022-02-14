import Foundation

/// Represents a card in the dashboard collection view
class DashboardCardModel: Hashable {
    let id: DashboardCard
    let cellViewModel: NSDictionary?
    let entity: BlogDashboardRemoteEntity?

    init(id: DashboardCard, cellViewModel: NSDictionary? = nil, entity: BlogDashboardRemoteEntity? = nil) {
        self.id = id
        self.cellViewModel = cellViewModel
        self.entity = entity
    }

    static func == (lhs: DashboardCardModel, rhs: DashboardCardModel) -> Bool {
        lhs.cellViewModel == rhs.cellViewModel
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(cellViewModel)
    }
}

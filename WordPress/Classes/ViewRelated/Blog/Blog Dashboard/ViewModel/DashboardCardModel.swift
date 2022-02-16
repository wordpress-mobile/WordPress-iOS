import Foundation

/// Represents a card in the dashboard collection view
class DashboardCardModel: Hashable {
    let id: DashboardCard
    let apiResponse: BlogDashboardRemoteEntity?

    // Used as the `Hashable` to check if the cell should be updated or not
    let apiResponseDictionary: NSDictionary?

    init(id: DashboardCard, apiResponseDictionary: NSDictionary? = nil, entity: BlogDashboardRemoteEntity? = nil) {
        self.id = id
        self.apiResponseDictionary = apiResponseDictionary
        self.apiResponse = entity
    }

    static func == (lhs: DashboardCardModel, rhs: DashboardCardModel) -> Bool {
        lhs.apiResponseDictionary == rhs.apiResponseDictionary
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(apiResponseDictionary)
    }
}

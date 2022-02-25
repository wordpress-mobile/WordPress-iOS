import Foundation

/// Represents a card in the dashboard collection view
struct DashboardCardModel: Hashable {
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
        return lhs.id == rhs.id &&
            lhs.apiResponseDictionary == rhs.apiResponseDictionary
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(apiResponseDictionary)
    }
}

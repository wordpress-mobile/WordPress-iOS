import Foundation

/// Represents a card in the dashboard collection view
struct DashboardCardModel: Hashable {
    let id: DashboardCard
    let dotComID: Int
    let apiResponse: BlogDashboardRemoteEntity?

    /// Used as the `Hashable` to compare this `struct` to others
    let hashableDictionary: NSDictionary?

    /**
     Initializes a new DashboardCardModel, used as a model for each dashboard card.

     - Parameters:
     - id: The `DashboardCard` id of this card
     - hashableDictionary: A `NSDictionary?` that is used to compare this model to others
     - entity: A `BlogDashboardRemoteEntity?` property

     - Returns: A `DashboardCardModel` that is used by the dashboard diffable collection
                view. The `hashableDictionary` and the `id` is used to differentiate one
                card from the other.
    */
    init(id: DashboardCard, dotComID: Int, hashableDictionary: NSDictionary? = nil, entity: BlogDashboardRemoteEntity? = nil) {
        self.id = id
        self.dotComID = dotComID
        self.hashableDictionary = hashableDictionary
        self.apiResponse = entity
    }

    static func == (lhs: DashboardCardModel, rhs: DashboardCardModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.dotComID == rhs.dotComID &&
        lhs.hashableDictionary == rhs.hashableDictionary
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(dotComID)
        hasher.combine(hashableDictionary)
    }
}

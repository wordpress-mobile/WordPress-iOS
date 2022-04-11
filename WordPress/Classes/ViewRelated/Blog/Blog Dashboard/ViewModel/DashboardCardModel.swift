import Foundation

/// Represents a card in the dashboard collection view
struct DashboardCardModel: Hashable {
    let cardType: DashboardCard
    let dotComID: Int
    let apiResponse: BlogDashboardRemoteEntity?

    /// Used as the `Hashable` to compare this `struct` to others
    let hashableDictionary: NSDictionary?

    /**
     Initializes a new DashboardCardModel, used as a model for each dashboard card.

     - Parameters:
     - id: The `DashboardCard` id of this card
     - dotComID: The blog id for the blog associated with this card
     - hashableDictionary: A `NSDictionary?` that is used to compare this model to others
     - entity: A `BlogDashboardRemoteEntity?` property

     - Returns: A `DashboardCardModel` that is used by the dashboard diffable collection
                view. The `hashableDictionary`, `id`, and the `dotComID` is used to differentiate one
                card from the other.
    */
    init(cardType: DashboardCard, dotComID: Int, hashableDictionary: NSDictionary? = nil, entity: BlogDashboardRemoteEntity? = nil) {
        self.cardType = cardType
        self.dotComID = dotComID
        self.hashableDictionary = hashableDictionary
        self.apiResponse = entity
    }

    static func == (lhs: DashboardCardModel, rhs: DashboardCardModel) -> Bool {
        lhs.cardType == rhs.cardType &&
        lhs.dotComID == rhs.dotComID &&
        lhs.hashableDictionary == rhs.hashableDictionary
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(cardType)
        hasher.combine(dotComID)
        hasher.combine(hashableDictionary)
    }
}

import Foundation

enum DashboardCardModel: Hashable {

    case normal(DashboardNormalCardModel)
    case dynamic(DashboardDynamicCardModel)

    var cardType: DashboardCard {
        switch self {
        case .normal(let model): return model.cardType
        case .dynamic: return .dynamic
        }
    }

    func normal() -> DashboardNormalCardModel? {
        guard case .normal(let model) = self else {
            return nil
        }
        return model
    }

    func dynamic() -> DashboardDynamicCardModel? {
        guard case .dynamic(let model) = self else {
            return nil
        }
        return model
    }
}

extension DashboardCardModel: BlogDashboardAnalyticPropertiesProviding {

    var blogDashboardAnalyticProperties: [AnyHashable: Any] {
        var properties = cardType.blogDashboardAnalyticProperties
        if case let .dynamic(model) = self {
            let extra: [AnyHashable: Any] = ["id": model.payload.id]
            properties = properties.merging(extra, uniquingKeysWith: { first, second in
                return first
            })
        }
        return properties
    }
}

extension DashboardCardModel: BlogDashboardPersonalizable {

    var blogDashboardPersonalizationKey: String? {
        switch self {
        case .default(let card): return card.cardType.blogDashboardPersonalizationKey
        case .dynamic(let card): return "dynamic_card_\(card.payload.id)"
        }
    }

    var blogDashboardPersonalizationSettingsScope: BlogDashboardPersonalizationService.SettingsScope {
        return cardType.blogDashboardPersonalizationSettingsScope
    }
}


/// Represents a card in the dashboard collection view
struct DashboardNormalCardModel: Hashable {
    let cardType: DashboardCard
    let dotComID: Int
    let apiResponse: BlogDashboardRemoteEntity?

    /**
     Initializes a new DashboardCardModel, used as a model for each dashboard card.

     - Parameters:
     - id: The `DashboardCard` id of this card
     - dotComID: The blog id for the blog associated with this card
     - entity: A `BlogDashboardRemoteEntity?` property

     - Returns: A `DashboardCardModel` that is used by the dashboard diffable collection
                view. The `id`, `dotComID` and the `entity` is used to differentiate one
                card from the other.
    */
    init(cardType: DashboardCard, dotComID: Int, entity: BlogDashboardRemoteEntity? = nil) {
        self.cardType = cardType
        self.dotComID = dotComID
        self.apiResponse = entity
    }

    static func == (lhs: DashboardNormalCardModel, rhs: DashboardNormalCardModel) -> Bool {
        lhs.cardType == rhs.cardType &&
        lhs.dotComID == rhs.dotComID &&
        lhs.apiResponse == rhs.apiResponse
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(cardType)
        hasher.combine(dotComID)
        hasher.combine(apiResponse)
    }
}

struct DashboardDynamicCardModel: Hashable {

    typealias Payload = BlogDashboardRemoteEntity.BlogDashboardDynamic

    let payload: Payload
    let dotComID: Int
}

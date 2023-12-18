import Foundation

enum DashboardCardModel: Hashable {

    case normal(DashboardNormalCardModel)
    case dynamic(DashboardDynamicCardModel)

    var cardType: DashboardCard {
        switch self {
        case .normal(let model): return model.cardType
        case .dynamic(let model): return model.cardType
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

extension DashboardCardModel: BlogDashboardPersonalizable, BlogDashboardAnalyticPropertiesProviding {

    private var model: BlogDashboardPersonalizable & BlogDashboardAnalyticPropertiesProviding {
        switch self {
        case .normal(let card): return card
        case .dynamic(let card): return card
        }
    }

    var blogDashboardPersonalizationKey: String? {
        return model.blogDashboardPersonalizationKey
    }

    var blogDashboardPersonalizationSettingsScope: BlogDashboardPersonalizationService.SettingsScope {
        return model.blogDashboardPersonalizationSettingsScope
    }

    var analyticProperties: [AnyHashable: Any] {
        return model.analyticProperties
    }
}

// MARK: - Normal Card Model

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

extension DashboardNormalCardModel: BlogDashboardPersonalizable, BlogDashboardAnalyticPropertiesProviding {

    var blogDashboardPersonalizationKey: String? {
        return cardType.blogDashboardPersonalizationKey
    }

    var blogDashboardPersonalizationSettingsScope: BlogDashboardPersonalizationService.SettingsScope {
        return cardType.blogDashboardPersonalizationSettingsScope
    }

    var analyticProperties: [AnyHashable: Any] {
        return cardType.analyticProperties
    }
}

// MARK: - Dynamic Card Model

struct DashboardDynamicCardModel: Hashable {

    typealias Payload = BlogDashboardRemoteEntity.BlogDashboardDynamic

    let cardType: DashboardCard = .dynamic
    let payload: Payload
    let dotComID: Int
}

extension DashboardDynamicCardModel: BlogDashboardPersonalizable, BlogDashboardAnalyticPropertiesProviding {

    var blogDashboardPersonalizationKey: String? {
        return "dynamic_card_\(payload.id)"
    }

    var blogDashboardPersonalizationSettingsScope: BlogDashboardPersonalizationService.SettingsScope {
        return .siteSpecific
    }

    var analyticProperties: [AnyHashable: Any] {
        let properties: [AnyHashable: Any] = ["id": payload.id]
        return cardType.analyticProperties.merging(properties, uniquingKeysWith: { first, second in
            return first
        })
    }
}

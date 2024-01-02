import Foundation
import WordPressKit

final class BlogDashboardService {

    private let remoteService: DashboardServiceRemote
    private let persistence: BlogDashboardPersistence
    private let postsParser: BlogDashboardPostsParser
    private let repository: UserPersistentRepository
    private let isJetpack: Bool
    private let isDotComAvailable: Bool
    private let shouldShowJetpackFeatures: Bool

    init(
        managedObjectContext: NSManagedObjectContext,
        isJetpack: Bool,
        isDotComAvailable: Bool,
        shouldShowJetpackFeatures: Bool,
        remoteService: DashboardServiceRemote? = nil,
        persistence: BlogDashboardPersistence = BlogDashboardPersistence(),
        repository: UserPersistentRepository = UserDefaults.standard,
        postsParser: BlogDashboardPostsParser? = nil
    ) {
        self.isJetpack = isJetpack
        self.isDotComAvailable = isDotComAvailable
        self.shouldShowJetpackFeatures = shouldShowJetpackFeatures
        self.remoteService = remoteService ?? DashboardServiceRemote(wordPressComRestApi: WordPressComRestApi.defaultApi(in: managedObjectContext, localeKey: WordPressComRestApi.LocaleKeyV2))
        self.persistence = persistence
        self.repository = repository
        self.postsParser = postsParser ?? BlogDashboardPostsParser(managedObjectContext: managedObjectContext)
    }

    /// Fetch cards from remote
    func fetch(blog: Blog, completion: @escaping ([DashboardCardModel]) -> Void, failure: (([DashboardCardModel]) -> Void)? = nil) {

        guard let dotComID = blog.dotComID?.intValue else {
            failure?([])
            return
        }

        let cardsToFetch: [String] = DashboardCard.RemoteDashboardCard.allCases.filter {$0.supported(by: blog)}.map { $0.rawValue }

        remoteService.fetch(cards: cardsToFetch, forBlogID: dotComID, success: { [weak self] cardsDictionary in

            guard let cardsDictionary = self?.parseCardsForLocalContent(cardsDictionary, blog: blog) else {
                failure?([])
                return
            }

            if let cards = self?.decode(cardsDictionary, blog: blog) {

                blog.dashboardState.hasCachedData = true
                blog.dashboardState.failedToLoad = false

                self?.persistence.persist(cards: cardsDictionary, for: dotComID)

                guard let items = self?.parse(cards, blog: blog, dotComID: dotComID) else {
                    failure?([])
                    return
                }

                completion(items)
            } else {
                blog.dashboardState.failedToLoad = true
                failure?([])
            }

        }, failure: { [weak self] _ in
            blog.dashboardState.failedToLoad = true
            let items = self?.fetchLocal(blog: blog)
            failure?(items ?? [])
        })
    }

    /// Fetch cards from local
    func fetchLocal(blog: Blog) -> [DashboardCardModel] {

        guard AccountHelper.isDotcomAvailable(), let dotComID = blog.dotComID?.intValue else {
            return []
        }

        if let cardsDictionary = persistence.getCards(for: dotComID),
           let cardsWithLocalData = parseCardsForLocalContent(cardsDictionary, blog: blog),
           let cards = decode(cardsWithLocalData, blog: blog) {

            blog.dashboardState.hasCachedData = true
            let items = parse(cards, blog: blog, dotComID: dotComID)
            return items
        } else {
            blog.dashboardState.hasCachedData = false
            return localCards(blog: blog, dotComID: dotComID)
        }
    }
}

private extension BlogDashboardService {

    func parse(_ entity: BlogDashboardRemoteEntity?, blog: Blog, dotComID: Int) -> [DashboardCardModel] {
        let personalizationService = BlogDashboardPersonalizationService(repository: repository, siteID: dotComID)

        // Map `DashboardCard` instances to `DashboardCardModel`
        var allCards: [DashboardCardModel] = DashboardCard.allCases.compactMap { card -> DashboardCardModel? in
            guard card != .dynamic else {
                return nil
            }
            return self.dashboardCardModel(
                from: card,
                entity: entity,
                blog: blog,
                dotComID: dotComID,
                personalizationService: personalizationService
            )
        }

        // Maps dynamic cards to `DashboardCardModel`.
        if let dynamic = entity?.dynamic?.value {
            let cards = dynamic.compactMap { payload in
                return self.dashboardCardModel(
                    for: blog,
                    payload: payload,
                    dotComID: dotComID,
                    personalizationService: personalizationService
                )
            }
            let cardsByOrder = Dictionary(grouping: cards) { card -> BlogDashboardRemoteEntity.BlogDashboardDynamic.Order in
                guard case .dynamic(let model) = card, let order = model.payload.order else {
                    return .bottom
                }
                return order
            }
            let topCards = cardsByOrder[.top, default: []]
            let bottomCards = cardsByOrder[.bottom, default: []]

            // Adds "top" cards at the beginning of the list.
            allCards = topCards + allCards

            // Adds "bottom" cards at the bottom of the list just before "personalize" card.
            if allCards.last?.cardType == .personalize {
                allCards.insert(contentsOf: bottomCards, at: allCards.endIndex - 1)
            } else {
                allCards = allCards + bottomCards
            }
        }

        // Add "empty" card if the list of cards is empty.
        if allCards.isEmpty || allCards.map(\.cardType) == [.personalize] {
            let model = DashboardCardModel.normal(.init(cardType: .empty, dotComID: dotComID))
            allCards.insert(model, at: 0)
        }

        return allCards
    }

    func dashboardCardModel(
        from card: DashboardCard,
        entity: BlogDashboardRemoteEntity?,
        blog: Blog,
        dotComID: Int,
        personalizationService: BlogDashboardPersonalizationService
    ) -> DashboardCardModel? {
        guard personalizationService.isEnabled(card) else {
            return nil
        }

        guard card.shouldShow(
            for: blog,
            apiResponse: entity,
            isJetpack: isJetpack,
            isDotComAvailable: isDotComAvailable,
            shouldShowJetpackFeatures: shouldShowJetpackFeatures
        ) else {
            return nil
        }

        return .normal(.init(cardType: card, dotComID: dotComID, entity: entity))
    }

    func dashboardCardModel(
        for blog: Blog,
        payload: DashboardDynamicCardModel.Payload,
        dotComID: Int,
        personalizationService: BlogDashboardPersonalizationService
    ) -> DashboardCardModel? {
        let model = DashboardDynamicCardModel(payload: payload, dotComID: dotComID)
        let shouldShow = DashboardCard.shouldShowDynamicCard(
            for: blog,
            isJetpack: isJetpack
        )
        guard shouldShow, personalizationService.isEnabled(model) else {
            return nil
        }
        return .dynamic(model)
    }

    func decode(_ cardsDictionary: NSDictionary, blog: Blog) -> BlogDashboardRemoteEntity? {
        guard let data = try? JSONSerialization.data(withJSONObject: cardsDictionary, options: []) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .supportMultipleDateFormats
        return try? decoder.decode(BlogDashboardRemoteEntity.self, from: data)
    }

    func parseCardsForLocalContent(_ cardsDictionary: NSDictionary, blog: Blog) -> NSDictionary? {
        guard let cardsDictionary = cardsDictionary.mutableCopy() as? NSMutableDictionary,
              let posts = cardsDictionary[DashboardCard.RemoteDashboardCard.posts.rawValue] as? NSDictionary else {
            return cardsDictionary
        }

        // TODO: Add similar logic here for parsing pages
        cardsDictionary["posts"] = postsParser.parse(posts, for: blog)
        return cardsDictionary
    }

    func localCards(blog: Blog, dotComID: Int) -> [DashboardCardModel] {
        parse(nil, blog: blog, dotComID: dotComID)
    }
}

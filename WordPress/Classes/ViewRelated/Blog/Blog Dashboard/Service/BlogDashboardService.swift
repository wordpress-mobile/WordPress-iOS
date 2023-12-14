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
        var cards: [DashboardCardModel] = DashboardCard.allCases.compactMap { card in
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

            return DashboardCardModel(cardType: card, dotComID: dotComID, entity: entity)
        }
        if cards.isEmpty || cards.map(\.cardType) == [.personalize] {
            cards.insert(DashboardCardModel(cardType: .empty, dotComID: dotComID), at: 0)
        }
        return cards
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

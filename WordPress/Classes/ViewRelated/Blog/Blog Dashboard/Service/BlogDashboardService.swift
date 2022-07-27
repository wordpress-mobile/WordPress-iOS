import Foundation
import WordPressKit

class BlogDashboardService {

    private let remoteService: DashboardServiceRemote
    private let persistence: BlogDashboardPersistence
    private let postsParser: BlogDashboardPostsParser

    init(managedObjectContext: NSManagedObjectContext, remoteService: DashboardServiceRemote? = nil, persistence: BlogDashboardPersistence = BlogDashboardPersistence(), postsParser: BlogDashboardPostsParser? = nil) {
        self.remoteService = remoteService ?? DashboardServiceRemote(wordPressComRestApi: WordPressComRestApi.defaultApi(in: managedObjectContext, localeKey: WordPressComRestApi.LocaleKeyV2))
        self.persistence = persistence
        self.postsParser = postsParser ?? BlogDashboardPostsParser(managedObjectContext: managedObjectContext)
    }

    /// Fetch cards from remote
    func fetch(blog: Blog, completion: @escaping ([DashboardCardModel]) -> Void, failure: (([DashboardCardModel]) -> Void)? = nil) {

        guard let dotComID = blog.dotComID?.intValue else {
            failure?([])
            return
        }

        let cardsToFetch: [String] = DashboardCard.RemoteDashboardCard.allCases.map { $0.rawValue }

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

        guard let dotComID = blog.dotComID?.intValue else {
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
        var items: [DashboardCardModel] = []
        DashboardCard.allCases.forEach { card in
            guard card.shouldShow(for: blog, apiResponse: entity) else {
                return
            }

            let cardModel = DashboardCardModel(cardType: card, dotComID: dotComID, entity: entity)
            items.append(cardModel)
        }
        return items
    }

    func decode(_ cardsDictionary: NSDictionary, blog: Blog) -> BlogDashboardRemoteEntity? {
        guard let data = try? JSONSerialization.data(withJSONObject: cardsDictionary, options: []) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try? decoder.decode(BlogDashboardRemoteEntity.self, from: data)
    }

    func parseCardsForLocalContent(_ cardsDictionary: NSDictionary, blog: Blog) -> NSDictionary? {
        guard let cardsDictionary = cardsDictionary.mutableCopy() as? NSMutableDictionary,
              let posts = cardsDictionary[DashboardCard.RemoteDashboardCard.posts.rawValue] as? NSDictionary else {
            return cardsDictionary
        }

        cardsDictionary["posts"] = postsParser.parse(posts, for: blog)
        return cardsDictionary
    }

    func localCards(blog: Blog, dotComID: Int) -> [DashboardCardModel] {
        parse(nil, blog: blog, dotComID: dotComID)
    }
}

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
    func fetch(blog: Blog, completion: @escaping (DashboardSnapshot) -> Void, failure: ((DashboardSnapshot?) -> Void)? = nil) {

        guard let dotComID = blog.dotComID?.intValue else {
            return
        }

        let cardsToFetch: [String] = DashboardCard.remoteCases.map { $0.rawValue }

        remoteService.fetch(cards: cardsToFetch, forBlogID: dotComID, success: { [weak self] cardsDictionary in

            guard let cardsDictionary = self?.parseCardsForLocalContent(cardsDictionary, blog: blog) else {
                return
            }

            if let cards = self?.decode(cardsDictionary, blog: blog) {

                blog.dashboardState.hasCachedData = true
                blog.dashboardState.failedToLoad = false

                self?.persistence.persist(cards: cardsDictionary, for: dotComID)

                guard let snapshot = self?.parse(cardsDictionary, cards: cards, blog: blog, dotComID: dotComID) else {
                    return
                }

                completion(snapshot)
            } else {
                blog.dashboardState.failedToLoad = true
                failure?(nil)
            }

        }, failure: { [weak self] _ in
            blog.dashboardState.failedToLoad = true
            let snapshot = self?.fetchLocal(blog: blog)
            failure?(snapshot)
        })
    }

    /// Fetch cards from local
    func fetchLocal(blog: Blog) -> DashboardSnapshot {

        guard let dotComID = blog.dotComID?.intValue else {
            return DashboardSnapshot()
        }

        if let cardsDictionary = persistence.getCards(for: dotComID),
           let cardsWithLocalData = parseCardsForLocalContent(cardsDictionary, blog: blog),
           let cards = decode(cardsWithLocalData, blog: blog) {

            blog.dashboardState.hasCachedData = true
            let snapshot = parse(cardsWithLocalData, cards: cards, blog: blog, dotComID: dotComID)
            return snapshot
        } else {
            blog.dashboardState.hasCachedData = false
            return localCards(blog: blog, dotComID: dotComID)
        }
    }
}

private extension BlogDashboardService {
    /// We use the `BlogDashboardRemoteEntity` to inject it into cells
    /// The `NSDictionary` is used for `Hashable` purposes
    func parse(_ cardsDictionary: NSDictionary, cards: BlogDashboardRemoteEntity, blog: Blog, dotComID: Int) -> DashboardSnapshot {
        var snapshot = DashboardSnapshot()

        snapshot.appendSections(DashboardSection.allCases)
        snapshot.appendItems([.quickActions], toSection: .quickActions)

        DashboardCard.allCases
            .forEach { card in

            if card.isRemote {
                if let viewModel = cardsDictionary[card.rawValue] {
                    let cardModel = DashboardCardModel(cardType: card,
                                                  dotComID: dotComID,
                                                  hashableDictionary: viewModel as? NSDictionary,
                                                  entity: cards)

                    snapshot.appendItems([.cards(cardModel)], toSection: .cards)
                }
            } else {

                guard card.shouldShow(for: blog) else {
                    return
                }

                let cardModel = DashboardCardModel(cardType: card, dotComID: dotComID)
                snapshot.appendItems([.cards(cardModel)], toSection: .cards)
            }

        }

        return snapshot
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
              let posts = cardsDictionary[DashboardCard.posts.rawValue] as? NSDictionary else {
            return cardsDictionary
        }

        cardsDictionary["posts"] = postsParser.parse(posts, for: blog)
        return cardsDictionary
    }

    func localCards(blog: Blog, dotComID: Int) -> DashboardSnapshot {
        parse([:], cards: BlogDashboardRemoteEntity(), blog: blog, dotComID: dotComID)
    }
}

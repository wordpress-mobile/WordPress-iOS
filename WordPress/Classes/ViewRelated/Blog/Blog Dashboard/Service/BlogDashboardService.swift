import Foundation
import WordPressKit

class BlogDashboardService {

    private let remoteService: DashboardServiceRemote
    private let persistence: BlogDashboardPersistence
    private let state: BlogDashboardState

    init(managedObjectContext: NSManagedObjectContext, remoteService: DashboardServiceRemote? = nil, persistence: BlogDashboardPersistence = BlogDashboardPersistence(), state: BlogDashboardState = BlogDashboardState.shared) {
        self.remoteService = remoteService ?? DashboardServiceRemote(wordPressComRestApi: WordPressComRestApi.defaultApi(in: managedObjectContext, localeKey: WordPressComRestApi.LocaleKeyV2))
        self.persistence = persistence
        self.state = state
    }

    /// Fetch cards from remote
    func fetch(blog: Blog, completion: @escaping (DashboardSnapshot) -> Void, failure: ((DashboardSnapshot?) -> Void)? = nil) {

        guard let dotComID = blog.dotComID?.intValue else {
            return
        }

        let cardsToFetch: [String] = DashboardCard.remoteCases.map { $0.rawValue }

        remoteService.fetch(cards: cardsToFetch, forBlogID: dotComID, success: { [weak self] cardsDictionary in

            if let cards = self?.decode(cardsDictionary) {

                self?.state.hasCachedData = true
                self?.state.failedToLoad = false

                self?.persistence.persist(cards: cardsDictionary, for: dotComID)

                guard let snapshot = self?.parse(cardsDictionary, cards: cards, blog: blog) else {
                    return
                }

                completion(snapshot)
            } else {
                self?.state.failedToLoad = true
                failure?(nil)
            }

        }, failure: { [weak self] _ in
            self?.state.failedToLoad = true
            let snapshot = self?.fetchLocal(blog: blog)
            failure?(snapshot)
        })
    }

    /// Fetch cards from local
    func fetchLocal(blog: Blog) -> DashboardSnapshot {
        if let dotComID = blog.dotComID?.intValue,
            let cardsDictionary = persistence.getCards(for: dotComID),
            let cards = decode(cardsDictionary) {

            state.hasCachedData = true
            let snapshot = parse(cardsDictionary, cards: cards, blog: blog)
            return snapshot
        } else {
            state.hasCachedData = false
            return localCards(blog: blog)
        }
    }
}

private extension BlogDashboardService {
    /// We use the `BlogDashboardRemoteEntity` to inject it into cells
    /// The `NSDictionary` is used for `Hashable` purposes
    func parse(_ cardsDictionary: NSDictionary, cards: BlogDashboardRemoteEntity, blog: Blog) -> DashboardSnapshot {
        var snapshot = DashboardSnapshot()

        DashboardCard.allCases
            .forEach { card in

            if card.isRemote {
                if let viewModel = cardsDictionary[card.rawValue] {
                    let section = DashboardCardSection(id: card)
                    let item = DashboardCardModel(id: card, hashableDictionary: viewModel as? NSDictionary, entity: cards)

                    snapshot.appendSections([section])
                    snapshot.appendItems([item], toSection: section)
                }
            } else {

                guard card.shouldShow(for: blog) else {
                    return
                }

                let section = DashboardCardSection(id: card)
                let item = DashboardCardModel(id: card)

                snapshot.appendSections([section])
                snapshot.appendItems([item], toSection: section)
            }

        }

        return snapshot
    }

    func decode(_ cardsDictionary: NSDictionary) -> BlogDashboardRemoteEntity? {
        guard let data = try? JSONSerialization.data(withJSONObject: cardsDictionary, options: []) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try? decoder.decode(BlogDashboardRemoteEntity.self, from: data)
    }

    func localCards(blog: Blog) -> DashboardSnapshot {
        parse([:], cards: BlogDashboardRemoteEntity(), blog: blog)
    }
}

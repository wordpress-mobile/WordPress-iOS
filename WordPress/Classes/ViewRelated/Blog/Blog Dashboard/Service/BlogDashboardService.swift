import Foundation
import WordPressKit

class BlogDashboardService {

    var blog: Blog

    private let remoteService: DashboardServiceRemote
    private let persistence: BlogDashboardPersistence

    init(blog: Blog, managedObjectContext: NSManagedObjectContext, remoteService: DashboardServiceRemote? = nil, persistence: BlogDashboardPersistence = BlogDashboardPersistence()) {
        self.blog = blog
        self.remoteService = remoteService ?? DashboardServiceRemote(wordPressComRestApi: WordPressComRestApi.defaultApi(in: managedObjectContext, localeKey: WordPressComRestApi.LocaleKeyV2))
        self.persistence = persistence
    }

    /// Fetch cards from remote
    func fetch(wpComID: Int, completion: @escaping (DashboardSnapshot) -> Void, failure: (() -> Void)? = nil) {
        let cardsToFetch: [String] = DashboardCard.remoteCases.map { $0.rawValue }

        remoteService.fetch(cards: cardsToFetch, forBlogID: wpComID, success: { [weak self] cardsDictionary in

            if let cards = self?.decode(cardsDictionary) {

                self?.persistence.persist(cards: cardsDictionary, for: wpComID)

                guard let snapshot = self?.parse(cardsDictionary, cards: cards) else {
                    return
                }

                completion(snapshot)
            } else {
                failure?()
            }

        }, failure: { _ in
            failure?()
        })
    }

    /// Fetch cards from local
    func fetchLocal(wpComID: Int) -> DashboardSnapshot {
        if let cardsDictionary = persistence.getCards(for: wpComID),
            let cards = decode(cardsDictionary) {

            let snapshot = parse(cardsDictionary, cards: cards)
            return snapshot
        }

        return DashboardSnapshot()
    }
}

private extension BlogDashboardService {
    /// We use the `BlogDashboardRemoteEntity` to inject it into cells
    /// The `NSDictionary` is used for `Hashable` purposes
    func parse(_ cardsDictionary: NSDictionary, cards: BlogDashboardRemoteEntity) -> DashboardSnapshot {
        var snapshot = DashboardSnapshot()

        DashboardCard.allCases.forEach { card in

            if card.isRemote {
                if let viewModel = cardsDictionary[card.rawValue] {
                    let section = DashboardCardSection(id: card)
                    let item = DashboardCardModel(id: card, apiResponseDictionary: viewModel as? NSDictionary, entity: cards)

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
}

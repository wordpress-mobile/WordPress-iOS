import Foundation
import WordPressKit

class BlogDashboardService {

    private let remoteService: DashboardServiceRemote
    private let persistence: BlogDashboardPersistence

    init(managedObjectContext: NSManagedObjectContext, remoteService: DashboardServiceRemote? = nil, persistence: BlogDashboardPersistence = BlogDashboardPersistence()) {
        self.remoteService = remoteService ?? DashboardServiceRemote(wordPressComRestApi: WordPressComRestApi.defaultApi(in: managedObjectContext, localeKey: WordPressComRestApi.LocaleKeyV2))
        self.persistence = persistence
    }

    /// Fetch cards from remote
    func fetch(blog: Blog, completion: @escaping (DashboardSnapshot) -> Void, failure: (() -> Void)? = nil) {

        guard let wpComID = blog.dotComID?.intValue else {
            return
        }

        let cardsToFetch: [String] = DashboardCard.remoteCases.map { $0.rawValue }

        remoteService.fetch(cards: cardsToFetch, forBlogID: wpComID, success: { [weak self] cardsDictionary in

            if let cards = self?.decode(cardsDictionary) {

                self?.persistence.persist(cards: cardsDictionary, for: wpComID)

                guard let snapshot = self?.parse(cardsDictionary, cards: cards, blog: blog, wpComID: wpComID) else {
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
    func fetchLocal(blog: Blog) -> DashboardSnapshot {

        guard let wpComID = blog.dotComID?.intValue else {
            return DashboardSnapshot()
        }

        if let cardsDictionary = persistence.getCards(for: wpComID),
            let cards = decode(cardsDictionary) {

            let snapshot = parse(cardsDictionary, cards: cards, blog: blog, wpComID: wpComID)
            return snapshot
        } else {
            return localCardsAndGhostCards(blog: blog, wpComID: wpComID)
        }
    }
}

private extension BlogDashboardService {
    /// We use the `BlogDashboardRemoteEntity` to inject it into cells
    /// The `NSDictionary` is used for `Hashable` purposes
    func parse(_ cardsDictionary: NSDictionary, cards: BlogDashboardRemoteEntity, blog: Blog, wpComID: Int) -> DashboardSnapshot {
        var snapshot = DashboardSnapshot()

        DashboardCard.allCases
            .filter { $0 != .ghost }
            .forEach { card in

            if card.isRemote {
                if let viewModel = cardsDictionary[card.rawValue] {
                    let section = DashboardCardSection(id: card)
                    let item = DashboardCardModel(id: card,
                                                  wpComID: wpComID,
                                                  hashableDictionary: viewModel as? NSDictionary,
                                                  entity: cards)

                    snapshot.appendSections([section])
                    snapshot.appendItems([item], toSection: section)
                }
            } else {

                guard card.shouldShow(for: blog) else {
                    return
                }

                let section = DashboardCardSection(id: card)
                let item = DashboardCardModel(id: card, wpComID: wpComID)

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

    func localCardsAndGhostCards(blog: Blog, wpComID: Int) -> DashboardSnapshot {
        var snapshot = localCards(blog: blog, wpComID: wpComID)

        let section = DashboardCardSection(id: .ghost)

        snapshot.appendSections([section])
        Array(0...4).forEach {
            snapshot.appendItems([DashboardCardModel(id: .ghost,
                                                     wpComID: wpComID,
                                                     hashableDictionary: ["diff": $0])], toSection: section)
        }

        return snapshot
    }

    func localCards(blog: Blog, wpComID: Int) -> DashboardSnapshot {
        parse([:], cards: BlogDashboardRemoteEntity(), blog: blog, wpComID: wpComID)
    }
}

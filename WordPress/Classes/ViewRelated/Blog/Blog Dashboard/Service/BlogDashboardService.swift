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
    func fetch(wpComID: Int, completion: @escaping (DashboardSnapshot) -> Void, failure: (() -> Void)? = nil) {
        let cardsToFetch: [String] = DashboardCard.remoteCases.map { $0.rawValue }

        remoteService.fetch(cards: cardsToFetch, forBlogID: wpComID, success: { [weak self] cards in

            self?.persistence.persist(cards: cards, for: wpComID)

            guard let snapshot = self?.parse(cards) else {
                return
            }

            completion(snapshot)

        }, failure: { _ in
            failure?()
        })
    }

    /// Fetch cards from local
    func fetchLocal(wpComID: Int) -> DashboardSnapshot {
        if let cards = persistence.getCards(for: wpComID) {
            let snapshot = parse(cards)
            return snapshot
        }

        return DashboardSnapshot()
    }
}

private extension BlogDashboardService {
    func parse(_ cards: NSDictionary) -> DashboardSnapshot {
        var snapshot = DashboardSnapshot()

        DashboardCard.allCases.forEach { card in

            if card.isRemote {

                if card == .posts,
                   let posts = cards[DashboardCard.posts.rawValue] as? NSDictionary {
                    let (sections, items) = parsePostCard(posts)
                    snapshot.appendSections(sections)
                    sections.enumerated().forEach { key, section in
                        snapshot.appendItems([items[key]], toSection: section)
                    }
                } else {

                    if let viewModel = cards[card.rawValue] {
                        let section = DashboardCardSection(id: card.rawValue)
                        let item = DashboardCardModel(id: card, cellViewModel: viewModel as? NSDictionary)

                        snapshot.appendSections([section])
                        snapshot.appendItems([item], toSection: section)
                    }

                }

            } else {
                let section = DashboardCardSection(id: card.rawValue)
                let item = DashboardCardModel(id: card)

                snapshot.appendSections([section])
                snapshot.appendItems([item], toSection: section)
            }

        }

        return snapshot
    }

    /// Posts are a special case: they might not be a 1-1 relation
    /// If the user has draft and scheduled posts, we show two cards
    /// One for each. This function takes care of this
    func parsePostCard(_ posts: NSDictionary) -> ([DashboardCardSection], [DashboardCardModel]) {
        var sections: [DashboardCardSection] = []
        var items: [DashboardCardModel] = []

        let draftsCount = (posts["draft"] as? Array<Any>)?.count ?? 0
        let scheduledCount = (posts["scheduled"] as? Array<Any>)?.count ?? 0

        let hasDrafts = draftsCount > 0
        let hasScheduled = scheduledCount > 0

        if hasDrafts && hasScheduled {
            var draft = posts.copy() as? [String: Any]
            draft?["show_drafts"] = true
            draft?["show_scheduled"] = false
            sections.append(DashboardCardSection(id: "posts", subtype: "draft"))
            items.append(DashboardCardModel(id: .posts, cellViewModel: draft as NSDictionary?))

            var scheduled = posts.copy() as? [String: Any]
            scheduled?["show_drafts"] = false
            scheduled?["show_scheduled"] = true
            sections.append(DashboardCardSection(id: "posts", subtype: "scheduled"))
            items.append(DashboardCardModel(id: .posts, cellViewModel: scheduled as NSDictionary?))
        } else {
            var postsWithFlags = posts.copy() as? [String: Any]
            postsWithFlags?["show_drafts"] = hasDrafts
            postsWithFlags?["show_scheduled"] = hasScheduled

            sections.append(DashboardCardSection(id: "posts"))
            items.append(DashboardCardModel(id: .posts, cellViewModel: postsWithFlags as NSDictionary?))
        }

        return (sections, items)
    }
}

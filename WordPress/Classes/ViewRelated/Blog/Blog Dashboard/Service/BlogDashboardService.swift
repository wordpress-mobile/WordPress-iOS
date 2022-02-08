import Foundation
import WordPressKit

class BlogDashboardService {
    let remoteService: DashboardServiceRemote

    init(managedObjectContext: NSManagedObjectContext, remoteService: DashboardServiceRemote? = nil) {
        self.remoteService = remoteService ?? DashboardServiceRemote(wordPressComRestApi: WordPressComRestApi.defaultApi(in: managedObjectContext, localeKey: WordPressComRestApi.LocaleKeyV2))
    }

    func fetch(wpComID: Int, completion: @escaping (DashboardSnapshot) -> Void) {
        let cardsToFetch: [String] = DashboardCard.remoteCases.map { $0.rawValue }

        remoteService.fetch(cards: cardsToFetch, forBlogID: wpComID, success: { [weak self] cards in

            var snapshot = DashboardSnapshot()

            DashboardCard.allCases.forEach { card in

                if card.isRemote {

                    if card == .posts,
                       let posts = cards[DashboardCard.posts.rawValue] as? NSDictionary,
                       let (sections, items) = self?.parsePostCard(posts) {
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

            completion(snapshot)
        }, failure: { _ in

        })
    }
}

private extension BlogDashboardService {
    /// Posts are a special case: they might not be a 1-1 relation
    /// If the user has draft and scheduled posts, we show two cards
    /// One for each. This function takes care of this
    func parsePostCard(_ posts: NSDictionary) -> ([DashboardCardSection], [DashboardCardModel]) {
        var sections: [DashboardCardSection] = []
        var items: [DashboardCardModel] = []

        let hasDrafts = (posts["draft"] as? Array<Any>)?.count ?? 0 > 0
        let hasScheduled = (posts["scheduled"] as? Array<Any>)?.count ?? 0 > 0

        if hasDrafts && hasScheduled {
            var drafts = posts.copy() as? [String: Any]
            drafts?["scheduled"] = []
            sections.append(DashboardCardSection(id: "posts", subtype: "draft"))
            items.append(DashboardCardModel(id: .posts, cellViewModel: drafts as NSDictionary?))

            var scheduled = posts.copy() as? [String: Any]
            scheduled?["draft"] = []
            sections.append(DashboardCardSection(id: "posts", subtype: "scheduled"))
            items.append(DashboardCardModel(id: .posts, cellViewModel: scheduled as NSDictionary?))
        } else {
            sections.append(DashboardCardSection(id: "posts"))
            items.append(DashboardCardModel(id: .posts, cellViewModel: posts))
        }

        return (sections, items)
    }
}

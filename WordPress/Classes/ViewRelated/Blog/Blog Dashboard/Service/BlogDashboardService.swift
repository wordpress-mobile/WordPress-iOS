import Foundation
import Gridicons
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

                    if card == .quickActions, let items = self?.createQuickActionsItems() {
                        let section = DashboardCardSection(id: card.rawValue)
                        snapshot.appendSections([section])
                        snapshot.appendItems(items, toSection: section)
                    } else {
                        let section = DashboardCardSection(id: card.rawValue)
                        let item = DashboardCardModel(id: card)

                        snapshot.appendSections([section])
                        snapshot.appendItems([item], toSection: section)
                    }

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

    func createQuickActionsItems() -> [DashboardCardModel] {
        let stats = createQuickActionsCardModel(title: "Stats", icon: .gridicon(.statsAlt))
        let posts = createQuickActionsCardModel(title: "Posts", icon: .gridicon(.posts))
        let media = createQuickActionsCardModel(title: "Media", icon: .gridicon(.image))
        let pages = createQuickActionsCardModel(title: "Pages", icon: .gridicon(.pages))
        return [stats, posts, media, pages]
    }

    func createQuickActionsCardModel(title: String, icon: UIImage) -> DashboardCardModel {
        let viewModel = [
            "title": title,
            "icon": icon
        ] as NSDictionary
        return DashboardCardModel(id: .quickActions, cellViewModel: viewModel)
    }
}

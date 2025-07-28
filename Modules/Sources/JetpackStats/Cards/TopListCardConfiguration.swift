import Foundation

struct TopListCardConfiguration: Codable {
    let id: UUID
    var item: TopListItemType
    var metric: SiteMetric

    init(id: UUID = UUID(), item: TopListItemType, metric: SiteMetric) {
        self.id = id
        self.item = item
        self.metric = metric
    }
}

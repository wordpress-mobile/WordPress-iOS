import Foundation

/// This struct contains data for the Insights All Time stats to be displayed in the corresponding widget.
///

struct AllTimeWidgetStats: Codable {
    let views: Int
    let visitors: Int
    let posts: Int
    let bestViews: Int

    init(views: Int? = 0, visitors: Int? = 0, posts: Int? = 0, bestViews: Int? = 0) {
        self.views = views ?? 0
        self.visitors = visitors ?? 0
        self.posts = posts ?? 0
        self.bestViews = bestViews ?? 0
    }
}

extension AllTimeWidgetStats: Equatable {
    static func == (lhs: AllTimeWidgetStats, rhs: AllTimeWidgetStats) -> Bool {
        return lhs.views == rhs.views &&
            lhs.visitors == rhs.visitors &&
            lhs.posts == rhs.posts &&
            lhs.bestViews == rhs.bestViews
    }
}

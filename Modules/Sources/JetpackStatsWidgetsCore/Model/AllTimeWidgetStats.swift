import Foundation

/// This struct contains data for the Insights All Time stats to be displayed in the corresponding widget.
///

public struct AllTimeWidgetStats: Codable, Equatable {
    public let views: Int
    public let visitors: Int
    public let posts: Int
    public let bestViews: Int

    public init(views: Int? = 0, visitors: Int? = 0, posts: Int? = 0, bestViews: Int? = 0) {
        self.views = views ?? 0
        self.visitors = visitors ?? 0
        self.posts = posts ?? 0
        self.bestViews = bestViews ?? 0
    }
}

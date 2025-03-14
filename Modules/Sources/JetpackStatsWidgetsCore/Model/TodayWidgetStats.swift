import Foundation

/// This struct contains data for the Insights Today stats to be displayed in the corresponding widget.
///

public struct TodayWidgetStats: Codable, Equatable {
    public let views: Int
    public let visitors: Int
    public let likes: Int
    public let comments: Int

    public init(views: Int? = 0, visitors: Int? = 0, likes: Int? = 0, comments: Int? = 0) {
        self.views = views ?? 0
        self.visitors = visitors ?? 0
        self.likes = likes ?? 0
        self.comments = comments ?? 0
    }
}

import CocoaLumberjack
import Foundation

/// This struct contains data for the Insights Today stats to be displayed in the corresponding widget.
///

struct TodayWidgetStats: Codable {
    let views: Int
    let visitors: Int
    let likes: Int
    let comments: Int

    init(views: Int? = 0, visitors: Int? = 0, likes: Int? = 0, comments: Int? = 0) {
        self.views = views ?? 0
        self.visitors = visitors ?? 0
        self.likes = likes ?? 0
        self.comments = comments ?? 0
    }
}

extension TodayWidgetStats: Equatable {
    static func == (lhs: TodayWidgetStats, rhs: TodayWidgetStats) -> Bool {
        return lhs.views == rhs.views &&
            lhs.visitors == rhs.visitors &&
            lhs.likes == rhs.likes &&
            lhs.comments == rhs.comments
    }
}

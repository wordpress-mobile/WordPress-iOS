import Foundation
import WordPressKit

typealias StatsTrafficBarChartTabIndex = Int
enum StatsTrafficBarChartTabs: Int, CaseIterable {
    case views = 0, visitors, likes, comments

    typealias CountKeyPath = KeyPath<StatsSummaryData, Int>

    var count: CountKeyPath {
        switch self {
        case .views:
            return \.viewsCount
        case .visitors:
            return \.visitorsCount
        case .likes:
            return \.likesCount
        case .comments:
            return \.commentsCount
        }
    }

    var analyticsEvent: WPAnalyticsStat {
        switch self {
        case .views:
            return .statsOverviewTypeTappedViews
        case .visitors:
            return .statsOverviewTypeTappedVisitors
        case .likes:
            return .statsOverviewTypeTappedLikes
        case .comments:
            return .statsOverviewTypeTappedComments
        }
    }
}

extension StatsTrafficBarChartTabs {
    var accessibleDescription: String {
        switch self {
        case .views:
            return NSLocalizedString(
                "stats.traffic.accessibilityLabel.views",
                value: "Bar Chart depicting Views for selected period",
                comment: "This description is used to set the accessibility label for the Stats Traffic chart, with Views selected."
            )
        case .visitors:
            return NSLocalizedString(
                "stats.traffic.accessibilityLabel.visitors",
                value: "Bar Chart depicting Visitors for the selected period.",
                comment: "This description is used to set the accessibility label for the Stats Traffic chart, with Visitors selected."
            )
        case .likes:
            return NSLocalizedString(
                "stats.traffic.accessibilityLabel.likes",
                value: "Bar Chart depicting Likes for the selected period.",
                comment: "This description is used to set the accessibility label for the Stats Traffic chart, with Likes selected."
            )
        case .comments:
            return NSLocalizedString(
                "stats.traffic.accessibilityLabel.comments",
                value: "Bar Chart depicting Comments for the selected period.",
                comment: "This description is used to set the accessibility label for the Stats Traffic chart, with Comments selected."
            )
        }
    }
}

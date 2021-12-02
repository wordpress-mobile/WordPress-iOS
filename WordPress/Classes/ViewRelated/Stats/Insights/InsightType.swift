import Foundation

enum InsightType: Int, SiteStatsPinnable {
    case growAudience
    case customize
    case latestPostSummary
    case allTimeStats
    case followersTotals
    case mostPopularTime
    case tagsAndCategories
    case annualSiteStats
    case comments
    case followers
    case todaysStats
    case postingActivity
    case publicize
    case allDotComFollowers
    case allEmailFollowers
    case allComments
    case allTagsAndCategories
    case allAnnual

    // These Insights will be displayed in this order if a site's Insights have not been customized.
    static let defaultInsights = [InsightType.latestPostSummary,
                                  .todaysStats,
                                  .allTimeStats,
                                  .followersTotals
    ]

    static let defaultInsightsValues = InsightType.defaultInsights.map { $0.rawValue }

    static func typesForValues(_ values: [Int]) -> [InsightType] {
        return values.compactMap { InsightType(rawValue: $0) }
    }

    static func valuesForTypes(_ types: [InsightType]) -> [Int] {
        return types.compactMap { $0.rawValue }
    }

    var statSection: StatSection? {
        switch self {
        case .latestPostSummary:
            return .insightsLatestPostSummary
        case .allTimeStats:
            return .insightsAllTime
        case .followersTotals:
            return .insightsFollowerTotals
        case .mostPopularTime:
            return .insightsMostPopularTime
        case .tagsAndCategories:
            return .insightsTagsAndCategories
        case .annualSiteStats:
            return .insightsAnnualSiteStats
        case .comments:
            return .insightsCommentsPosts
        case .followers:
            return .insightsFollowersEmail
        case .todaysStats:
            return .insightsTodaysStats
        case .postingActivity:
            return .insightsPostingActivity
        case .publicize:
            return .insightsPublicize
        default:
            return nil
        }
    }
}

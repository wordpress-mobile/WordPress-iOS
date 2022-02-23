import Foundation
import WordPressKit

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
    /// returns the data to fetch for each card type. Some cards may require more than one type.
    /// The same type might be needed for more than one card.
    var insightsDataForSection: [InsightDataType] {
        switch self {
        case .mostPopularTime, .annualSiteStats:
            return [.annualAndMostPopular]
        case .followers:
            return [.followers]
        case .followersTotals:
            return [.followers, .publicize]
        case .publicize:
            return [.publicize]
        case .growAudience, .allTimeStats:
            return [.allTime]
        case .todaysStats:
            return [.today]
        case .comments:
            return [.comments]
        case .postingActivity:
            return [.postingActivity]
        case .latestPostSummary:
            return [.latestPost]
        case .tagsAndCategories:
            return [.tagsAndCategories]
        default:
            return []
        }
    }
}


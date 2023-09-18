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
    // New stats revamp cards – May 2022
    case viewsVisitors
    case likesTotals
    case commentsTotals

    // These Insights will be displayed in this order if a site's Insights have not been customized.
    static var defaultInsights: [InsightType] {
        if AppConfiguration.statsRevampV2Enabled {
            return [.viewsVisitors,
                    .likesTotals,
                    .commentsTotals,
                    .followersTotals,
                    .mostPopularTime,
                    .latestPostSummary]
        } else {
            return [.mostPopularTime,
                    .allTimeStats,
                    .todaysStats,
                    .followers,
                    .comments]
        }
    }

    // This property is here to update the default list on existing installations.
    // If the list saved on UserDefaults matches the old one, it will be updated to the new one above.
    static var oldDefaultInsights: [InsightType] {
        if AppConfiguration.statsRevampV2Enabled {
            return [.mostPopularTime,
                    .allTimeStats,
                    .todaysStats,
                    .followers,
                    .comments]
        } else {
            return [.latestPostSummary,
                    .todaysStats,
                    .allTimeStats,
                    .followersTotals]
        }
    }

    static let defaultInsightsValues = InsightType.defaultInsights.map { $0.rawValue }

    static func typesForValues(_ values: [Int]) -> [InsightType] {
        return values.compactMap { InsightType(rawValue: $0) }
    }

    static func valuesForTypes(_ types: [InsightType]) -> [Int] {
        return types.compactMap { $0.rawValue }
    }

    var statSection: StatSection? {
        switch self {
        case .viewsVisitors:
            return .insightsViewsVisitors
        case .latestPostSummary:
            return .insightsLatestPostSummary
        case .allTimeStats:
            return .insightsAllTime
        case .likesTotals:
            return .insightsLikesTotals
        case .commentsTotals:
            return .insightsCommentsTotals
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

/// Represents the api to be called by one (or more) insight card(s)
/// It's used to support cases like two or more cards that need the same api call,
/// as well as cards that need more than one api call
enum InsightDataType: Int {
    case latestPost
    case allTime
    case annualAndMostPopular
    case followers
    case publicize
    case tagsAndCategories
    case comments
    case today
    case postingActivity
}

@objc enum StatSection: Int {
    case periodOverview
    case periodPostsAndPages
    case periodReferrers
    case periodClicks
    case periodAuthors
    case periodCountries
    case periodSearchTerms
    case periodPublished
    case periodVideos
    case insightsLatestPostSummary
    case insightsAllTime
    case insightsFollowerTotals
    case insightsMostPopularTime
    case insightsTagsAndCategories
    case insightsAnnualSiteStats
    case insightsCommentsAuthors
    case insightsCommentsPosts
    case insightsFollowersWordPress
    case insightsFollowersEmail
    case insightsTodaysStats
    case insightsPostActivity
    case insightsPublicize
    case postDetailsGraph
    case postDetailsMonthsYears
    case postDetailsAveragePerDay
    case postDetailsRecentWeeks

    static let allInsights = [StatSection.insightsLatestPostSummary,
                              .insightsAllTime,
                              .insightsFollowerTotals,
                              .insightsMostPopularTime,
                              .insightsTagsAndCategories,
                              .insightsAnnualSiteStats,
                              .insightsCommentsAuthors,
                              .insightsCommentsPosts,
                              .insightsFollowersWordPress,
                              .insightsFollowersEmail,
                              .insightsTodaysStats,
                              .insightsPostActivity,
                              .insightsPublicize
    ]

    static let allPeriods = [StatSection.periodOverview,
                             .periodPostsAndPages,
                             .periodReferrers,
                             .periodClicks,
                             .periodAuthors,
                             .periodCountries,
                             .periodSearchTerms,
                             .periodPublished,
                             .periodVideos
    ]

}

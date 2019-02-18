enum StatSection: Int {
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
    case insightsComments
    case insightsFollowers
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
                              .insightsComments,
                              .insightsFollowers,
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

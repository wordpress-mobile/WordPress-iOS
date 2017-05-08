typedef NS_ENUM(NSInteger, StatsSection) {
    StatsSectionGraph,
    StatsSectionPeriodHeader,
    StatsSectionEvents,
    StatsSectionPosts,
    StatsSectionReferrers,
    StatsSectionClicks,
    StatsSectionCountry,
    StatsSectionVideos,
    StatsSectionAuthors,
    StatsSectionSearchTerms,
    StatsSectionComments,
    StatsSectionTagsCategories,
    StatsSectionFollowers,
    StatsSectionPublicize,
    StatsSectionWebVersion,
    StatsSectionPostDetailsLoadingIndicator,
    StatsSectionPostDetailsGraph,
    StatsSectionPostDetailsMonthsYears,
    StatsSectionPostDetailsAveragePerDay,
    StatsSectionPostDetailsRecentWeeks,
    StatsSectionInsightsMostPopular,
    StatsSectionInsightsPostActivity,
    StatsSectionInsightsAllTime,
    StatsSectionInsightsTodaysStats,
    StatsSectionInsightsLatestPostSummary
};

typedef NS_ENUM(NSInteger, StatsSubSection) {
    StatsSubSectionCommentsByAuthor = 100,
    StatsSubSectionCommentsByPosts,
    StatsSubSectionFollowersDotCom,
    StatsSubSectionFollowersEmail,
    StatsSubSectionNone
};

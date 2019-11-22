protocol StatsStoreCacheable {
    associatedtype StatsStoreType

    func containsCachedData(for type: StatsStoreType) -> Bool
    func containsCachedData(for types: [StatsStoreType]) -> Bool
}

extension StatsStoreCacheable {
    func containsCachedData(for types: [StatsStoreType]) -> Bool {
        return types.first { containsCachedData(for: $0) } != nil
    }
}

extension StatsInsightsStore: StatsStoreCacheable {
    func containsCachedData(for type: InsightType) -> Bool {
        switch type {
        case .latestPostSummary:
            return state.lastPostInsight != nil
        case .allTimeStats:
            return state.allTimeStats != nil
        case .followersTotals, .followers:
            return state.dotComFollowers != nil &&
                state.emailFollowers != nil
        case .mostPopularTime, .annualSiteStats:
            return state.annualAndMostPopularTime != nil
        case .tagsAndCategories:
            return state.topTagsAndCategories != nil
        case .comments:
            return state.topCommentsInsight != nil
        case .todaysStats:
            return state.todaysStats != nil
        case .postingActivity:
            return state.postingActivity != nil
        case .publicize:
            return state.publicizeFollowers != nil
        case .allDotComFollowers:
            return state.allDotComFollowers != nil
        case .allEmailFollowers:
            return state.allEmailFollowers != nil
        case .allComments:
            return state.allCommentsInsight != nil
        case .allTagsAndCategories:
            return state.allTagsAndCategories != nil
        case .allAnnual:
            return state.allAnnual != nil
        default:
            return false
        }
    }
}

extension StatsPeriodStore: StatsStoreCacheable {
    func containsCachedData(for type: PeriodType) -> Bool {
        switch type {
        case .summary:
            return state.summary != nil
        case .topPostsAndPages:
            return state.topPostsAndPages != nil
        case .topReferrers:
            return state.topReferrers != nil
        case .topPublished:
            return state.topPublished != nil
        case .topClicks:
            return state.topClicks != nil
        case .topAuthors:
            return state.topAuthors != nil
        case .topSearchTerms:
            return state.topSearchTerms != nil
        case .topCountries:
            return state.topCountries != nil
        case .topVideos:
            return state.topVideos != nil
        case .topFileDownloads:
            return state.topFileDownloads != nil
        }
    }
}

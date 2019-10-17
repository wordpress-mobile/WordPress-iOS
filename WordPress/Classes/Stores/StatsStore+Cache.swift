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
        case .followersTotals:
            return false
        case .mostPopularTime, .annualSiteStats:
            return state.annualAndMostPopularTime != nil
        case .tagsAndCategories:
            return state.topTagsAndCategories != nil
        case .comments:
            return state.topCommentsInsight != nil
        case .followers:
            return state.dotComFollowers != nil &&
                state.emailFollowers != nil
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
        default:
            return false
        }
    }
}

import Foundation

/// Everything the redesigned card list needs beyond the view model. `nil`
/// on the list means "render the classic rows".
struct CustomPostCardConfiguration {
    let density: CustomPostListDensity
    /// Off for the Scheduled tab (future dates would all read "This week")
    /// and for search results (mixed statuses).
    let showsDateGroups: Bool
    let mediaCache: FeaturedMediaURLCache
    /// Only the Published tab carries a store; drafts have neither views nor comments.
    var metricsStore: CustomPostMetricsStore? = nil
    let grouper = CustomPostDateGrouper()
}

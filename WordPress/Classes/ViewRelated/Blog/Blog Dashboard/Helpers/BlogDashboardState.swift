import Foundation

class BlogDashboardState {
    private static var states: [NSNumber: BlogDashboardState] = [:]

    /// If the dashboard has cached data
    var hasCachedData = false

    /// If loading the cards in the dashboard failed
    var failedToLoad = false

    /// If the draft posts have been synced since launch
    /// If they are, the local data source should be preferred than the dashboard cards data source
    var draftsSynced = false

    /// If the scheduled posts have been synced since launch
    /// If they are, the local data source should be preferred than the dashboard cards data source
    var scheduledSynced = false

    /// If the dashboard is currently being loaded for the very first time
    /// aka: it has never been loaded before.
    var isFirstLoad: Bool {
        !hasCachedData && !failedToLoad
    }

    /// If the initial loading of the dashboard failed
    var isFirstLoadFailure: Bool {
        !hasCachedData && failedToLoad
    }

    @Atomic var postsSyncingStatuses: [BasePost.Status] = []
    @Atomic var pagesSyncingStatuses: [BasePost.Status] = []

    private init() { }

    /// Return the dashboard state for the given blog
    static func shared(for blog: Blog) -> BlogDashboardState {
        let dotComID = blog.dotComID ?? 0

        if let availableState = states[dotComID] {
            return availableState
        } else {
            states[dotComID] = BlogDashboardState()
            return states[dotComID]!
        }
    }

    /// Purge all saved dashboard states.
    /// Should be called on logout
    static func resetAllStates() {
        states.removeAll()
    }
}

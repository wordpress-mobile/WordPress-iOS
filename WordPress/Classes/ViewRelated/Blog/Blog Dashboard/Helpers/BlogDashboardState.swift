import Foundation

class BlogDashboardState {
    static let shared = BlogDashboardState()

    /// If the dashboard has cached data
    var hasCachedData = false

    /// If loading the cards in the dashboard failed
    var failedToLoad = false

    /// If the dashboard is currently being loaded for the very first time
    /// aka: it has never been loaded before.
    var isFirstLoad: Bool {
        !hasCachedData && !failedToLoad
    }

    /// If the initial loading of the dashboard failed
    var isFirstLoadFailure: Bool {
        !hasCachedData && failedToLoad
    }

    private init() { }

    func reset() {
        hasCachedData = false
        failedToLoad = false
    }
}

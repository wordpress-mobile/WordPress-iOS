import Foundation

class BlogDashboardState {
    static let shared = BlogDashboardState()

    /// If the dashboard has cached data
    var hasCachedData = false

    /// If loading the cards in the dashboard failed
    var loadingFailed = false

    /// If the dashboard is currently being loaded for the very first time
    /// aka: it has never been loaded before.
    var isFirstLoad: Bool {
        !hasCachedData && !loadingFailed
    }

    /// If the initial loading of the dashboard failed
    var isFirstLoadFailure: Bool {
        !hasCachedData && loadingFailed
    }

    private init() { }

    func reset() {
        hasCachedData = false
        loadingFailed = false
    }
}

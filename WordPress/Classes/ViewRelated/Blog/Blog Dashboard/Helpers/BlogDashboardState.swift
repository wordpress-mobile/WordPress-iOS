import Foundation

class BlogDashboardState {
    static let shared = BlogDashboardState()

    /// If the dashboard has ever loaded before
    var hasEverLoaded = false

    /// If loading the cards in the dashboard failed
    var loadingFailed = false

    /// If the dashboard is currently being loaded for the very first time
    /// aka: it has never been loaded before.
    var isFirstLoad: Bool {
        !hasEverLoaded && !loadingFailed
    }

    private init() { }

    func reset() {
        hasEverLoaded = false
        loadingFailed = false
    }
}

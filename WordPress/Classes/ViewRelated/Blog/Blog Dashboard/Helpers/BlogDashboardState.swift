import Foundation

class BlogDashboardState {
    static let shared = BlogDashboardState()

    /// If the dashboard is being loaded for the first time
    var firstTimeLoading = false

    /// If loading the cards in the dashboard failed
    var loadingFailed = false

    /// If the dashboard is currently being loaded for the very first time
    /// aka: it has never been loaded before.
    var isCurrentlyLoadingForTheVeryFirstTime: Bool {
        firstTimeLoading && !loadingFailed
    }

    private init() { }

    func reset() {
        firstTimeLoading = false
        loadingFailed = false
    }
}

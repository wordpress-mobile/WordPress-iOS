import Foundation

class BlogDashboardState {
    static let shared = BlogDashboardState()

    /// If the dashboard is being loaded for the first time
    var firstTimeLoading = false

    /// If loading the cards in the dashboard failed
    var loadingFailed = false

    private init() { }
}

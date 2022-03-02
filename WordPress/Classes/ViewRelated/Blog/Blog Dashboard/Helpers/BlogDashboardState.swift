import Foundation

class BlogDashboardState {
    static let shared = BlogDashboardState()

    var firstTimeLoading = false
    var initialLoadingFailed = false

    private init() { }
}

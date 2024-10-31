import Foundation

extension Blog {
    /// The state of the dashboard for the current blog
    var dashboardState: BlogDashboardState {
        BlogDashboardState.shared(for: self)
    }
}

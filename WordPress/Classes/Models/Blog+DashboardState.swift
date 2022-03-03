import Foundation

extension Blog {
    /// The state of the dashboard for the current blog
    var dashboard: BlogDashboardState {
        BlogDashboardState.standard(blog: self)
    }
}

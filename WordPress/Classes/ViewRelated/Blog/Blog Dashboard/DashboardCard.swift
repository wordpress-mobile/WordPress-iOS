import Foundation

/// Describes all the available cards.
///
/// Notice that the order here matters and it will take
/// precedence over the backend.
enum DashboardCard: String, CaseIterable {
    case quickActions
    case posts
    case todaysStats
}

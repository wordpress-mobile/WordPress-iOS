import Foundation

/// Describes all the available cards.
///
/// Notice that the order here matters and it will take
/// precedence over the backend.
///
/// If the card `isRemote` the `String` should match its
/// identifier on the backend.
enum DashboardCard: String, CaseIterable {
    case quickActions
    case quickStart
    case posts
    case todaysStats = "todays_stats"

    /// If the card is backed by API data
    var isRemote: Bool {
        switch self {
        case .quickActions:
            return false
        case .quickStart:
            return false
        case .posts:
            return true
        case .todaysStats:
            return true
        }
    }

    var cell: DashboardCollectionViewCell.Type {
        switch self {
        case .quickActions:
            return DashboardQuickActionsCardCell.self
        case .quickStart:
            return DashboardQuickStartCardCell.self
        case .posts:
            return DashboardPostsCardCell.self
        case .todaysStats:
            return DashboardStatsCardCell.self
        }
    }

    /// All cards that are remote
    static var remoteCases: [DashboardCard] {
        return DashboardCard.allCases.filter { $0.isRemote }
    }

    /// All cards that are local
    static var localCases: [DashboardCard] {
        return DashboardCard.allCases.filter { !$0.isRemote }
    }
}

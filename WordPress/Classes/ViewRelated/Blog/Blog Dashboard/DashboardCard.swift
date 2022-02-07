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
    case posts
    case todaysStats = "todays_stats"

    /// If the card is backed by API data
    var isRemote: Bool {
        switch self {
        case .quickActions:
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
            return HostCollectionViewCell<QuickLinksView>.self
        case .posts:
            return DashboardPostsCardCell.self
        case .todaysStats:
            return HostCollectionViewCell<QuickLinksView>.self
        }
    }
}

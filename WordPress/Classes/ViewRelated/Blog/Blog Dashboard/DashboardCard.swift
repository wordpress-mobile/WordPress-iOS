import Foundation

/// Describes all the available cards.
///
/// Notice that the order here matters and it will take
/// precedence over the backend.
///
/// Remote cards should be separately added to RemoteDashboardCard
enum DashboardCard: String, CaseIterable {
    case quickStart
    case prompts
    case todaysStats = "todays_stats"
    case posts

    // Card placeholder for when loading data
    case ghost
    case failure

    var cell: DashboardCollectionViewCell.Type {
        switch self {
        case .quickStart:
            return DashboardQuickStartCardCell.self
        case .posts:
            return DashboardPostsCardCell.self
        case .todaysStats:
            return DashboardStatsCardCell.self
        case .prompts:
            return DashboardPromptsCardCell.self
        case .ghost:
            return DashboardGhostCardCell.self
        case .failure:
            return DashboardFailureCardCell.self
        }
    }

    func shouldShow(for blog: Blog, mySiteSettings: MySiteSettings = MySiteSettings()) -> Bool {
        switch self {
        case .quickStart:
            return QuickStartTourGuide.shouldShowChecklist(for: blog) && mySiteSettings.defaultSection == .dashboard
        case .posts:
            return true
        case .todaysStats:
            return true
        case .prompts:
            return FeatureFlag.bloggingPrompts.enabled
        case .ghost:
            return blog.dashboardState.isFirstLoad
        case .failure:
            return blog.dashboardState.isFirstLoadFailure
        }
    }

    /// Includes all cards that should be fetched from the backend
    /// The `String` should match its identifier on the backend.
    enum RemoteDashboardCard: String, CaseIterable {
        case todaysStats = "todays_stats"
        case posts
    }
}

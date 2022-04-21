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
    case prompts
    case todaysStats = "todays_stats"
    case posts

    // Card placeholder for when loading data
    case ghost
    case failure

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
        case .prompts:
            return false // TODO: Change this to true later.
        case .ghost:
            return false
        case .failure:
            return false
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
        case .quickActions:
            return true
        case .quickStart:
            return QuickStartTourGuide.quickStartEnabled(for: blog) && mySiteSettings.defaultSection == .dashboard
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

    /// All cards that are remote
    static var remoteCases: [DashboardCard] {
        return DashboardCard.allCases.filter { $0.isRemote }
    }

    /// All cards that are local
    static var localCases: [DashboardCard] {
        return DashboardCard.allCases.filter { !$0.isRemote }
    }
}

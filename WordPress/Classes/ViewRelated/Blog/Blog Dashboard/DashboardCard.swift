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
    case draftPosts
    case scheduledPosts
    case nextPost = "create_next"
    case createPost = "create_first"

    // Card placeholder for when loading data
    case ghost
    case failure

    var cell: DashboardCollectionViewCell.Type {
        switch self {
        case .quickStart:
            return DashboardQuickStartCardCell.self
        case .draftPosts:
            return DashboardDraftPostsCardCell.self
        case .scheduledPosts:
            return DashboardScheduledPostsCardCell.self
        case .nextPost:
            return DashboardEmptyPostsCardCell.self
        case .createPost:
            return DashboardEmptyPostsCardCell.self
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

    func shouldShow(for blog: Blog, postsInfo: BlogDashboardPostsInfo? = nil, mySiteSettings: DefaultSectionProvider = MySiteSettings()) -> Bool {
        switch self {
        case .quickStart:
            return QuickStartTourGuide.shouldShowChecklist(for: blog) && mySiteSettings.defaultSection == .dashboard
        case .draftPosts:
            fallthrough
        case .scheduledPosts:
            fallthrough
        case .nextPost:
            fallthrough
        case .createPost:
            fallthrough
        case .todaysStats:
            return self.shouldShowRemoteCard(postsInfo: postsInfo)
        case .prompts:
            return FeatureFlag.bloggingPrompts.enabled
        case .ghost:
            return blog.dashboardState.isFirstLoad
        case .failure:
            return blog.dashboardState.isFirstLoadFailure
        }
    }

    private func shouldShowRemoteCard(postsInfo: BlogDashboardPostsInfo?) -> Bool {
        guard let postsInfo = postsInfo else {
            return false
        }
        switch self {
        case .draftPosts:
            return postsInfo.hasDrafts
        case .scheduledPosts:
            return postsInfo.hasScheduled
        case .nextPost:
            return postsInfo.hasNoDraftsOrScheduled && postsInfo.hasPublished
        case .createPost:
            return postsInfo.hasNoDraftsOrScheduled && !postsInfo.hasPublished
        case .todaysStats:
            return true
        default:
            return false
        }
    }

    /// Includes all cards that should be fetched from the backend
    /// The `String` should match its identifier on the backend.
    enum RemoteDashboardCard: String, CaseIterable {
        case todaysStats = "todays_stats"
        case posts
    }
}

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
    case nextPost
    case createPost

    // Card placeholder for when loading data
    case ghost
    case failure

    var cell: DashboardCollectionViewCell.Type {
        switch self {
        case .quickStart:
            return DashboardQuickStartCardCell.self
        case .draftPosts:
            fallthrough
        case .scheduledPosts:
            fallthrough
        case .nextPost:
            fallthrough
        case .createPost:
            return DashboardPostsCardCell.self // TODO: Return diff cell for each posts card
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

    func shouldShow(for blog: Blog, apiResponse: BlogDashboardRemoteEntity? = nil, mySiteSettings: DefaultSectionProvider = MySiteSettings()) -> Bool {
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
            return self.shouldShowPostsCard(apiResponse: apiResponse)
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

    private func shouldShowPostsCard(apiResponse: BlogDashboardRemoteEntity?) -> Bool {
        guard let apiResponse = apiResponse else {
            return false
        }
        switch self {
        case .draftPosts:
            return apiResponse.hasDrafts
        case .scheduledPosts:
            return apiResponse.hasScheduled
        case .nextPost:
            return apiResponse.hasNoDraftsOrScheduled && apiResponse.hasPublished
        case .createPost:
            return apiResponse.hasNoDraftsOrScheduled && !apiResponse.hasPublished
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

private extension BlogDashboardRemoteEntity {
    var hasDrafts: Bool {
        return (self.posts?.draft?.count ?? 0) > 0
    }

    var hasScheduled: Bool {
        return (self.posts?.scheduled?.count ?? 0) > 0
    }

    var hasNoDraftsOrScheduled: Bool {
        return !hasDrafts && !hasScheduled
    }

    var hasPublished: Bool {
        return self.posts?.hasPublished ?? true
    }
}

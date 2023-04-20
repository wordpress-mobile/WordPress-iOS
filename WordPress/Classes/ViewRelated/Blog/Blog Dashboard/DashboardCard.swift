import Foundation

/// Describes all the available cards.
///
/// Notice that the order here matters and it will take
/// precedence over the backend.
///
/// Remote cards should be separately added to RemoteDashboardCard
enum DashboardCard: String, CaseIterable {
    case jetpackInstall
    case quickStart
    case prompts
    case blaze
    case domainsDashboardCard
    case todaysStats = "todays_stats"
    case draftPosts
    case scheduledPosts
    case pages
    case activityLog
    case nextPost = "create_next"
    case createPost = "create_first"
    case jetpackBadge
    /// Card placeholder for when loading data
    case ghost
    case failure
    /// Empty state when no cards are present
    case empty
    /// A "Personalize Home Tab" button
    case personalize

    var cell: DashboardCollectionViewCell.Type {
        switch self {
        case .jetpackInstall:
            return DashboardJetpackInstallCardCell.self
        case .quickStart:
            return DashboardQuickStartCardCell.self
        case .draftPosts:
            return DashboardDraftPostsCardCell.self
        case .scheduledPosts:
            return DashboardScheduledPostsCardCell.self
        case .nextPost:
            return DashboardNextPostCardCell.self
        case .createPost:
            return DashboardFirstPostCardCell.self
        case .todaysStats:
            return DashboardStatsCardCell.self
        case .prompts:
            return DashboardPromptsCardCell.self
        case .ghost:
            return DashboardGhostCardCell.self
        case .failure:
            return DashboardFailureCardCell.self
        case .jetpackBadge:
            return DashboardBadgeCell.self
        case .blaze:
            return DashboardBlazeCardCell.self
        case .domainsDashboardCard:
            return DashboardDomainsCardCell.self
        case .empty:
            return BlogDashboardEmptyStateCell.self
        case .personalize:
            return BlogDashboardPersonalizeCardCell.self
        case .pages:
            return DashboardPagesListCardCell.self
        case .activityLog:
            return DashboardActivityLogCardCell.self
        }
    }

    var viewedAnalytic: WPAnalyticsEvent? {
        switch self {
        case .jetpackInstall:
            return .jetpackInstallFullPluginCardViewed
        case .prompts:
            return .promptsDashboardCardViewed
        default:
            return nil
        }
    }

    func shouldShow(for blog: Blog, apiResponse: BlogDashboardRemoteEntity? = nil, mySiteSettings: DefaultSectionProvider = MySiteSettings()) -> Bool {
        switch self {
        case .jetpackInstall:
            return JetpackInstallPluginHelper.shouldShowCard(for: blog)
        case .quickStart:
            return QuickStartTourGuide.quickStartEnabled(for: blog) && mySiteSettings.defaultSection == .dashboard
        case .draftPosts, .scheduledPosts, .todaysStats:
            return shouldShowRemoteCard(apiResponse: apiResponse)
        case .nextPost, .createPost:
            return !DashboardPromptsCardCell.shouldShowCard(for: blog) && shouldShowRemoteCard(apiResponse: apiResponse)
        case .prompts:
            return DashboardPromptsCardCell.shouldShowCard(for: blog)
        case .ghost:
            return blog.dashboardState.isFirstLoad
        case .failure:
            return blog.dashboardState.isFirstLoadFailure
        case .jetpackBadge:
            return JetpackBrandingVisibility.all.enabled
        case .blaze:
            return BlazeHelper.shouldShowCard(for: blog)
        case .domainsDashboardCard:
            return DomainsDashboardCardHelper.shouldShowCard(for: blog)
        case .empty:
            return false // Controlled manually based on other cards visibility
        case .personalize:
            return FeatureFlag.personalizeHomeTab.enabled
        case .pages:
            return DashboardPagesListCardCell.shouldShowCard(for: blog) && shouldShowRemoteCard(apiResponse: apiResponse)
        case .activityLog:
            return DashboardActivityLogCardCell.shouldShowCard(for: blog) && shouldShowRemoteCard(apiResponse: apiResponse)
        }
    }

    private func shouldShowRemoteCard(apiResponse: BlogDashboardRemoteEntity?) -> Bool {
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
        case .todaysStats:
            return true
        case .pages:
            return true
        case .activityLog:
            return true // FIXME: hide card if there's no activities
        default:
            return false
        }
    }

    /// A list of cards that can be shown/hidden on a "Personalize Home Tab" screen.
    static let personalizableCards: [DashboardCard] = [
        .todaysStats,
        .draftPosts,
        .scheduledPosts,
        .blaze,
        .prompts,
        .pages,
        .activityLog
    ]

    /// Includes all cards that should be fetched from the backend
    /// The `String` should match its identifier on the backend.
    enum RemoteDashboardCard: String, CaseIterable {
        case todaysStats = "todays_stats"
        case posts
        case pages
//        case activity // TODO: Uncomment this when activity log support is added to the endpoint
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

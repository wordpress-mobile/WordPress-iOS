import Foundation
import WordPressData
import Support

/// Describes all the available cards.
///
/// Notice that the order here matters and it will take
/// precedence over the backend.
///
/// Remote cards should be separately added to RemoteDashboardCard
enum DashboardCard: String, CaseIterable, Sendable {
    case dynamic
    case jetpackInstall
    case prompts
    case extensiveLogging
    case googleDomains
    case blaze
    case freeToPaidPlansDashboardCard
    case domainRegistration
    case todaysStats = "todays_stats"
    /// The new Stats "Today" card (matches the new Stats screen). Declared
    /// adjacent to `todaysStats` so it occupies the same dashboard position;
    /// the two are mutually exclusive (see `shouldShow`).
    case todaysStatsNew = "todays_stats_new"
    case draftPosts
    case scheduledPosts
    case pages
    case activityLog = "activity_log"
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
        case .dynamic:
            return BlogDashboardDynamicCardCell.self
        case .extensiveLogging:
            return DashboardExtensiveLoggingCardCell.self
        case .jetpackInstall:
            return DashboardJetpackInstallCardCell.self
        case .draftPosts:
            return DashboardDraftPostsCardCell.self
        case .scheduledPosts:
            return DashboardScheduledPostsCardCell.self
        case .todaysStats:
            return DashboardStatsCardCell.self
        case .todaysStatsNew:
            return DashboardTodayStatsNewCardCell.self
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
        case .freeToPaidPlansDashboardCard:
            return FreeToPaidPlansDashboardCardCell.self
        case .domainRegistration:
            return DashboardDomainRegistrationCardCell.self
        case .empty:
            return BlogDashboardEmptyStateCell.self
        case .personalize:
            return BlogDashboardPersonalizeCardCell.self
        case .pages:
            return DashboardPagesListCardCell.self
        case .activityLog:
            return DashboardActivityLogCardCell.self
        case .googleDomains:
            return DashboardGoogleDomainsCardCell.self
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

    func shouldShow(
        for blog: Blog,
        apiResponse: BlogDashboardRemoteEntity? = nil,
        // The following three parameter should not have default values.
        // Unfortunately, this method is called many times because the type is an enum with many cases^.
        //
        // At the time of writing, the priority is addressing a test failure and pave the way for better testability.
        // As such, we are leaving default values to keep compatibility with the existing code.
        //
        // ^ – See the following article for a better way to distribute configurations https://www.jessesquires.com/blog/2016/07/31/enums-as-configs/
        isJetpack: Bool = AppConfiguration.isJetpack,
        isDotComAvailable: Bool = AccountHelper.isDotcomAvailable(),
        shouldShowJetpackFeatures: Bool = JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures()
    ) -> Bool {
        switch self {
        case .jetpackInstall:
            return JetpackInstallPluginHelper.shouldShowCard(for: blog)
        case .draftPosts, .scheduledPosts:
            return shouldShowRemoteCard(apiResponse: apiResponse)
        case .todaysStats:
            return DashboardStatsCardCell.shouldShowCard(for: blog)
                && shouldShowRemoteCard(apiResponse: apiResponse)
                && !DashboardCard.newStatsActive(for: blog)
        case .todaysStatsNew:
            return DashboardCard.newStatsActive(for: blog)
                && DashboardStatsCardCell.shouldShowCard(for: blog)
                && shouldShowRemoteCard(apiResponse: apiResponse)
        case .prompts:
            return DashboardPromptsCardCell.shouldShowCard(for: blog)
        case .extensiveLogging:
            return ExtensiveLogging.enabled
        case .ghost:
            return blog.dashboardState.isFirstLoad
        case .failure:
            return blog.dashboardState.isFirstLoadFailure
        case .jetpackBadge:
            return JetpackBrandingVisibility.all.isEnabled(
                isWordPress: isJetpack == false,
                isDotComAvailable: isDotComAvailable,
                shouldShowJetpackFeatures: shouldShowJetpackFeatures
            )
        case .blaze:
            return BlazeHelper.shouldShowCard(for: blog)
        case .freeToPaidPlansDashboardCard:
            return FreeToPaidPlansDashboardCardHelper.shouldShowCard(for: blog)
        case .domainRegistration:
            return DomainCreditEligibilityChecker.canRedeemDomainCredit(blog: blog)
        case .empty:
            return false // Controlled manually based on other cards visibility
        case .personalize:
            return true
        case .pages:
            return DashboardPagesListCardCell.shouldShowCard(for: blog)
                && shouldShowRemoteCard(apiResponse: apiResponse)
        case .activityLog:
            return DashboardActivityLogCardCell.shouldShowCard(for: blog)
                && shouldShowRemoteCard(apiResponse: apiResponse)
        case .googleDomains:
            return FeatureFlag.googleDomainsCard.enabled && isJetpack
        case .dynamic:
            return false
        }
    }

    static func shouldShowDynamicCard(for blog: Blog, isJetpack: Bool = AppConfiguration.isJetpack) -> Bool {
        isJetpack && RemoteDashboardCard.dynamic.supported(by: blog)
    }

    /// Whether the new Stats "Today" card is eligible for `blog`.
    ///
    /// This is intentionally a side-effect-free predicate over stored properties
    /// only. It must NOT construct `StatsContext` or read
    /// `WPAccount.wordPressComRestApi`: that getter posts the
    /// sign-in-presenting `.wpAccountRequiresShowingSigninForWPComFixingAuthToken`
    /// notification when the token is missing, and the `StatsContext(blog:)`
    /// factory calls `wpAssertionFailure` on its failure path. Both are
    /// unacceptable during routine dashboard parsing, where failing this check is
    /// the normal legacy-fallback signal, not a bug. The stored `authToken` is
    /// read directly precisely because it has no such side effects.
    static func newStatsActive(for blog: Blog) -> Bool {
        guard FeatureFlag.newStats.enabled,
              blog.dotComID != nil,
              let authToken = blog.account?.authToken,
              !authToken.isEmpty else {
            return false
        }
        return true
    }

    private func shouldShowRemoteCard(apiResponse: BlogDashboardRemoteEntity?) -> Bool {
        guard let apiResponse else {
            return false
        }
        switch self {
        case .draftPosts:
            return apiResponse.hasDrafts
        case .scheduledPosts:
            return apiResponse.hasScheduled
        case .todaysStats, .todaysStatsNew:
            return apiResponse.hasStats
        case .pages:
            return apiResponse.hasPages
        case .activityLog:
            return apiResponse.hasActivities
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
        case activity
        case dynamic

        func supported(by blog: Blog) -> Bool {
            switch self {
            case .todaysStats:
                return DashboardStatsCardCell.shouldShowCard(for: blog)
            case .posts:
                return true
            case .pages:
                return DashboardPagesListCardCell.shouldShowCard(for: blog)
            case .activity:
                return DashboardActivityLogCardCell.shouldShowCard(for: blog)
            case .dynamic:
                return RemoteFeatureFlag.dynamicDashboardCards.enabled()
            }
        }
    }
}

private extension BlogDashboardRemoteEntity {
    var hasDrafts: Bool {
        (self.posts?.value?.draft?.count ?? 0) > 0
    }

    var hasScheduled: Bool {
        (self.posts?.value?.scheduled?.count ?? 0) > 0
    }

    var hasPages: Bool {
        self.pages?.value != nil
    }

    var hasStats: Bool {
        self.todaysStats?.value != nil
    }

    var hasActivities: Bool {
        (self.activity?.value?.current?.orderedItems?.count ?? 0) > 0
    }
}

// MARK: - BlogDashboardAnalyticPropertiesProviding Protocol Conformance

extension DashboardCard: BlogDashboardAnalyticPropertiesProviding {

    var analyticProperties: [AnyHashable: Any] {
        switch self {
        case .todaysStatsNew:
            // Report the same card identity as the legacy card so existing
            // card-shown/tapped funnels stay comparable across the flag.
            return ["card": DashboardCard.todaysStats.rawValue]
        default:
            return ["card": rawValue]
        }
    }
}

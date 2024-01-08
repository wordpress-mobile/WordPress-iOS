import Foundation

extension DashboardCard: BlogDashboardPersonalizable {

    var blogDashboardPersonalizationKey: String? {
        switch self {
        case .todaysStats:
            return "todays-stats-card-enabled-site-settings"
        case .draftPosts:
            return "draft-posts-card-enabled-site-settings"
        case .scheduledPosts:
            return "scheduled-posts-card-enabled-site-settings"
        case .blaze:
            return "blaze-card-enabled-site-settings"
        case .bloganuaryNudge:
            return "bloganuary-nudge-card-enabled-site-settings"
        case .prompts:
            // Warning: there is an irregularity with the prompts key that doesn't
            // have a "-card" component in the key name. Keeping it like this to
            // avoid having to migrate data.
            return "prompts-enabled-site-settings"
        case .freeToPaidPlansDashboardCard:
            return "free-to-paid-plans-dashboard-card-enabled-site-settings"
        case .domainRegistration:
            return "register-domain-dashboard-card"
        case .googleDomains:
            return "google-domains-card-enabled-site-settings"
        case .activityLog:
            return "activity-log-card-enabled-site-settings"
        case .pages:
            return "pages-card-enabled-site-settings"
        case .quickStart:
            // The "Quick Start" cell used to use `BlogDashboardPersonalizationService`.
            // It no longer does, but it's important to keep the flag around for
            // users that hidden it using this flag.
            return "quick-start-card-enabled-site-settings"
        case .dynamic, .jetpackBadge, .jetpackInstall, .jetpackSocial, .failure, .ghost, .personalize, .empty:
            return nil
        }
    }

    /// Specifies whether the card settings should be applied across
    /// different sites or only to a particular site.
    var blogDashboardPersonalizationSettingsScope: BlogDashboardPersonalizationService.SettingsScope {
        switch self {
        case .googleDomains:
            return .siteGeneric
        default:
            return .siteSpecific
        }
    }
}

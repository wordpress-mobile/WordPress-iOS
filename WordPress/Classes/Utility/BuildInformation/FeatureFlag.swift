/// FeatureFlag exposes a series of features to be conditionally enabled on
/// different builds.
@objc
enum FeatureFlag: Int, CaseIterable, OverrideableFlag {
    case jetpackDisconnect
    case debugMenu
    case readerCSS
    case unifiedAuth
    case homepageSettings
    case gutenbergMentions
    case gutenbergXposts
    case newNavBarAppearance
    case unifiedPrologueCarousel
    case stories
    case siteCreationHomePagePicker
    case jetpackScan
    case activityLogFilters
    case jetpackBackupAndRestore
    case todayWidget
    case unseenPosts
    case milestoneNotifications

    /// Returns a boolean indicating if the feature is enabled
    var enabled: Bool {
        if let overriddenValue = FeatureFlagOverrideStore().overriddenValue(for: self) {
            return overriddenValue
        }

        switch self {
        case .jetpackDisconnect:
            return BuildConfiguration.current == .localDeveloper
        case .debugMenu:
            return BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest]
        case .readerCSS:
            return false
        case .unifiedAuth:
            return true
        case .homepageSettings:
            return true
        case .gutenbergMentions:
            return true
        case .gutenbergXposts:
            return true
        case .newNavBarAppearance:
            return BuildConfiguration.current == .localDeveloper
        case .unifiedPrologueCarousel:
            return false
        case .stories:
            return BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest]
        case .siteCreationHomePagePicker:
            return true
        case .jetpackScan:
            return true
        case .activityLogFilters:
            return true
        case .jetpackBackupAndRestore:
            return true
        case .todayWidget:
            return true
        case .unseenPosts:
            return true
        case .milestoneNotifications:
            return false
        }
    }

    /// This key must match the server-side one for remote feature flagging
    var remoteKey: String? {
        switch self {
            case .unifiedAuth:
                return "wordpress_ios_unified_login_and_signup"
            default:
                return nil
        }
    }
}

/// Objective-C bridge for FeatureFlag.
///
/// Since we can't expose properties on Swift enums we use a class instead
class Feature: NSObject {
    /// Returns a boolean indicating if the feature is enabled
    @objc static func enabled(_ feature: FeatureFlag) -> Bool {
        return feature.enabled
    }
}

extension FeatureFlag {
    /// Descriptions used to display the feature flag override menu in debug builds
    var description: String {
        switch self {
        case .jetpackDisconnect:
            return "Jetpack disconnect"
        case .debugMenu:
            return "Debug menu"
        case .readerCSS:
            return "Ignore Reader CSS Cache"
        case .unifiedAuth:
            return "Unified Auth"
        case .homepageSettings:
            return "Homepage Settings"
        case .gutenbergMentions:
            return "Mentions in Gutenberg"
        case .gutenbergXposts:
            return "Xposts in Gutenberg"
        case .newNavBarAppearance:
            return "New Navigation Bar Appearance"
        case .unifiedPrologueCarousel:
            return "Unified Prologue Carousel"
        case .stories:
            return "Stories"
        case .siteCreationHomePagePicker:
            return "Site Creation: Home Page Picker"
        case .jetpackScan:
            return "Jetpack Scan"
        case .activityLogFilters:
            return "Jetpack's Activity Log Filters"
        case .jetpackBackupAndRestore:
            return "Jetpack Backup and Restore"
        case .todayWidget:
            return "iOS 14 Today Widget"
        case .unseenPosts:
            return "Unseen Posts in Reader"
        case .milestoneNotifications:
            return "Milestone notifications"
        }
    }

    var canOverride: Bool {
        switch self {
        case .debugMenu:
            return false
        case .newNavBarAppearance:
            return false
        case .todayWidget:
            return false
        default:
            return true
        }
    }
}

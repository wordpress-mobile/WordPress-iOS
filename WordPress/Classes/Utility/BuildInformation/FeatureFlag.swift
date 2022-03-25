/// FeatureFlag exposes a series of features to be conditionally enabled on
/// different builds.
@objc
enum FeatureFlag: Int, CaseIterable, OverrideableFlag {
    case bloggingPrompts
    case jetpackDisconnect
    case debugMenu
    case readerCSS
    case homepageSettings
    case unifiedPrologueCarousel
    case todayWidget
    case milestoneNotifications
    case bloggingReminders
    case siteIconCreator
    case weeklyRoundup
    case weeklyRoundupStaticNotification
    case weeklyRoundupBGProcessingTask
    case domains
    case timeZoneSuggester
    case aboutScreen
    case mySiteDashboard
    case mediaPickerPermissionsNotice
    case notificationCommentDetails
    case statsPerformanceImprovements
    case siteIntentQuestion

    /// Returns a boolean indicating if the feature is enabled
    var enabled: Bool {
        if let overriddenValue = FeatureFlagOverrideStore().overriddenValue(for: self) {
            return overriddenValue
        }

        switch self {
        case .bloggingPrompts:
            return false
        case .jetpackDisconnect:
            return BuildConfiguration.current == .localDeveloper
        case .debugMenu:
            return BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest, .a8cPrereleaseTesting]
        case .readerCSS:
            return false
        case .homepageSettings:
            return true
        case .unifiedPrologueCarousel:
            return true
        case .todayWidget:
            return true
        case .milestoneNotifications:
            return true
        case .bloggingReminders:
            return true
        case .siteIconCreator:
            return BuildConfiguration.current != .appStore
        case .weeklyRoundup:
            return true
        case .weeklyRoundupStaticNotification:
            // This may be removed, but we're feature flagging it for now until we know for sure we won't need it.
            return false
        case .weeklyRoundupBGProcessingTask:
            return true
        case .domains:
            return false
        case .timeZoneSuggester:
            return true
        case .aboutScreen:
            return true
        case .mySiteDashboard:
            return true
        case .mediaPickerPermissionsNotice:
            return true
        case .notificationCommentDetails:
            return true
        case .statsPerformanceImprovements:
            return true
        case .siteIntentQuestion:
            return false
        }
    }

    /// This key must match the server-side one for remote feature flagging
    var remoteKey: String? {
        switch self {
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
        case .bloggingPrompts:
            return "Blogging Prompts"
        case .jetpackDisconnect:
            return "Jetpack disconnect"
        case .debugMenu:
            return "Debug menu"
        case .readerCSS:
            return "Ignore Reader CSS Cache"
        case .homepageSettings:
            return "Homepage Settings"
        case .unifiedPrologueCarousel:
            return "Unified Prologue Carousel"
        case .todayWidget:
            return "iOS 14 Today Widget"
        case .milestoneNotifications:
            return "Milestone notifications"
        case .bloggingReminders:
            return "Blogging Reminders"
        case .siteIconCreator:
            return "Site Icon Creator"
        case .weeklyRoundup:
            return "Weekly Roundup"
        case .weeklyRoundupStaticNotification:
            return "Weekly Roundup Static Notification"
        case .weeklyRoundupBGProcessingTask:
            return "Weekly Roundup BGProcessingTask"
        case .domains:
            return "Domain Purchases"
        case .timeZoneSuggester:
            return "TimeZone Suggester"
        case .aboutScreen:
            return "New Unified About Screen"
        case .mySiteDashboard:
            return "My Site Dashboard"
        case .mediaPickerPermissionsNotice:
            return "Media Picker Permissions Notice"
        case .notificationCommentDetails:
            return "Notification Comment Details"
        case .statsPerformanceImprovements:
            return "Stats Performance Improvements"
        case .siteIntentQuestion:
            return "Site Intent Question"
        }
    }

    var canOverride: Bool {
        switch self {
        case .debugMenu:
            return false
        case .todayWidget:
            return false
        case .weeklyRoundup:
            return false
        case .weeklyRoundupStaticNotification:
            return false
        default:
            return true
        }
    }
}

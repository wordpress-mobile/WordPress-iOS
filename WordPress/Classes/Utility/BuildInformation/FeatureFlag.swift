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
    case mySiteDashboard
    case mediaPickerPermissionsNotice
    case notificationCommentDetails
    case statsPerformanceImprovements
    case siteIntentQuestion
    case landInTheEditor
    case statsNewAppearance
    case statsNewInsights
    case siteName
    case quickStartForExistingUsers
    case qrLogin
    case betaSiteDesigns
    case featureHighlightTooltip
    case jetpackPowered
    case jetpackPoweredBottomSheet
    case sharedUserDefaults
    case sharedLogin
    case newJetpackLandingScreen
    case newWordPressLandingScreen
    case newCoreDataContext

    /// Returns a boolean indicating if the feature is enabled
    var enabled: Bool {
        if let overriddenValue = FeatureFlagOverrideStore().overriddenValue(for: self) {
            return overriddenValue
        }

        switch self {
        case .bloggingPrompts:
            return AppConfiguration.isJetpack
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
            // Note: when used to control access to the domains feature, you should also check whether
            // the current AppConfiguration and blog support domains.
            // See BlogDetailsViewController.shouldShowDomainRegistration for an example.
            return true
        case .timeZoneSuggester:
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
            return true
        case .landInTheEditor:
            return false
        case .statsNewAppearance:
            return AppConfiguration.showsStatsRevampV2
        case .statsNewInsights:
            return AppConfiguration.showsStatsRevampV2
        case .siteName:
            return false
        case .quickStartForExistingUsers:
            return true
        case .qrLogin:
            return true
        case .betaSiteDesigns:
            return false
        case .featureHighlightTooltip:
            return true
        case .jetpackPowered:
            return true
        case .jetpackPoweredBottomSheet:
            return false
        case .sharedUserDefaults:
            return false
        case .sharedLogin:
            return false
        case .newJetpackLandingScreen:
            return true
        case .newWordPressLandingScreen:
            return false
        case .newCoreDataContext:
            return true
        }
    }

    var disabled: Bool {
        return enabled == false
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
        case .landInTheEditor:
            return "Land In The Editor"
        case .statsNewAppearance:
            return "New Appearance for Stats"
        case .statsNewInsights:
            return "New Cards for Stats Insights"
        case .siteName:
            return "Site Name"
        case .quickStartForExistingUsers:
            return "Quick Start For Existing Users"
        case .qrLogin:
            return "QR Code Login"
        case .betaSiteDesigns:
            return "Fetch Beta Site Designs"
        case .featureHighlightTooltip:
            return "Feature Highlight Tooltip"
        case .jetpackPowered:
            return "Jetpack powered banners and badges"
        case .jetpackPoweredBottomSheet:
            return "Jetpack powered bottom sheet"
        case .sharedUserDefaults:
            return "Shared User Defaults"
        case .sharedLogin:
            return "Shared Login"
        case .newJetpackLandingScreen:
            return "New Jetpack landing screen"
        case .newWordPressLandingScreen:
            return "New WordPress landing screen"
        case .newCoreDataContext:
            return "Use new Core Data context structure (Require app restart)"
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

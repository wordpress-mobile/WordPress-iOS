/// FeatureFlag exposes a series of features to be conditionally enabled on
/// different builds.
@objc
enum FeatureFlag: Int, CaseIterable {
    case bloggingPrompts
    case bloggingPromptsEnhancements
    case jetpackDisconnect
    case debugMenu
    case readerCSS
    case homepageSettings
    case unifiedPrologueCarousel
    case milestoneNotifications
    case bloggingReminders
    case siteIconCreator
    case weeklyRoundup
    case weeklyRoundupStaticNotification
    case weeklyRoundupBGProcessingTask
    case domains
    case timeZoneSuggester
    case mediaPickerPermissionsNotice
    case notificationCommentDetails
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
    case contentMigration
    case newJetpackLandingScreen
    case newWordPressLandingScreen
    case newCoreDataContext
    case jetpackIndividualPluginSupport
    case siteCreationDomainPurchasing
    case readerUserBlocking
    case personalizeHomeTab
    case commentModerationUpdate
    case compliancePopover
    case domainFocus
    case nativePhotoPicker
    case readerImprovements // pcdRpT-3Eb-p2

    /// Returns a boolean indicating if the feature is enabled
    var enabled: Bool {
        if let overriddenValue = FeatureFlagOverrideStore().overriddenValue(for: self) {
            return overriddenValue
        }

        switch self {
        case .bloggingPrompts:
            return AppConfiguration.isJetpack
        case .bloggingPromptsEnhancements:
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
        case .mediaPickerPermissionsNotice:
            return true
        case .notificationCommentDetails:
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
            return true
        case .contentMigration:
            return true
        case .newJetpackLandingScreen:
            return true
        case .newWordPressLandingScreen:
            return true
        case .newCoreDataContext:
            return true
        case .jetpackIndividualPluginSupport:
            return AppConfiguration.isJetpack
        case .siteCreationDomainPurchasing:
            return false
        case .readerUserBlocking:
            return true
        case .personalizeHomeTab:
            return AppConfiguration.isJetpack
        case .commentModerationUpdate:
            return false
        case .compliancePopover:
            return true
        case .domainFocus:
            return true
        case .nativePhotoPicker:
            return true
        case .readerImprovements:
            return false
        }
    }

    var disabled: Bool {
        return enabled == false
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
        case .bloggingPromptsEnhancements:
            return "Blogging Prompts Enhancements"
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
        case .mediaPickerPermissionsNotice:
            return "Media Picker Permissions Notice"
        case .notificationCommentDetails:
            return "Notification Comment Details"
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
        case .contentMigration:
            return "Content Migration"
        case .newJetpackLandingScreen:
            return "New Jetpack landing screen"
        case .newWordPressLandingScreen:
            return "New WordPress landing screen"
        case .newCoreDataContext:
            return "Use new Core Data context structure (Require app restart)"
        case .jetpackIndividualPluginSupport:
            return "Jetpack Individual Plugin Support"
        case .siteCreationDomainPurchasing:
            return "Site Creation Domain Purchasing"
        case .readerUserBlocking:
            return "Reader User Blocking"
        case .personalizeHomeTab:
            return "Personalize Home Tab"
        case .commentModerationUpdate:
            return "Comments Moderation Update"
        case .compliancePopover:
            return "Compliance Popover"
        case .domainFocus:
            return "Domain Focus"
        case .nativePhotoPicker:
            return "Native Photo Picker"
        case .readerImprovements:
            return "Reader Improvements v1"
        }
    }
}

extension FeatureFlag: OverridableFlag {

    var originalValue: Bool {
        return enabled
    }

    var canOverride: Bool {
        switch self {
        case .debugMenu:
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

/// FeatureFlag exposes a series of features to be conditionally enabled on
/// different builds.
@objc
enum FeatureFlag: Int, CaseIterable, OverrideableFlag {
    case jetpackDisconnect
    case debugMenu
    case readerCSS
    case homepageSettings
    case gutenbergMentions
    case gutenbergXposts
    case unifiedPrologueCarousel
    case stories
    case contactInfo
    case layoutGrid
    case siteCreationHomePagePicker
    case todayWidget
    case milestoneNotifications
    case bloggingReminders
    case siteIconCreator
    case globalStyleSettings
    case editorOnboardingHelpMenu
    case unifiedCommentsAndNotificationsList

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
        case .homepageSettings:
            return true
        case .gutenbergMentions:
            return true
        case .gutenbergXposts:
            return true
        case .unifiedPrologueCarousel:
            return true
        case .stories:
            return true
        case .contactInfo:
            return true
        case .layoutGrid:
            return true
        case .siteCreationHomePagePicker:
            return true
        case .todayWidget:
            return true
        case .milestoneNotifications:
            return true
        case .bloggingReminders:
            return true
        case .siteIconCreator:
            return BuildConfiguration.current != .appStore
        case .globalStyleSettings:
            return false
        case .editorOnboardingHelpMenu:
            return BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest]
        case .unifiedCommentsAndNotificationsList:
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
        case .jetpackDisconnect:
            return "Jetpack disconnect"
        case .debugMenu:
            return "Debug menu"
        case .readerCSS:
            return "Ignore Reader CSS Cache"
        case .homepageSettings:
            return "Homepage Settings"
        case .gutenbergMentions:
            return "Mentions in Gutenberg"
        case .gutenbergXposts:
            return "Xposts in Gutenberg"
        case .unifiedPrologueCarousel:
            return "Unified Prologue Carousel"
        case .stories:
            return "Stories"
        case .contactInfo:
            return "Contact Info"
        case .layoutGrid:
            return "Layout Grid"
        case .siteCreationHomePagePicker:
            return "Site Creation: Home Page Picker"
        case .todayWidget:
            return "iOS 14 Today Widget"
        case .milestoneNotifications:
            return "Milestone notifications"
        case .bloggingReminders:
            return "Blogging Reminders"
        case .siteIconCreator:
            return "Site Icon Creator"
        case .globalStyleSettings:
            return "Global Style Settings"
        case .editorOnboardingHelpMenu:
            return "Editor Onboarding Help Menu"
        case .unifiedCommentsAndNotificationsList:
            return "Unified List for Comments and Notifications"
        }
    }

    var canOverride: Bool {
        switch self {
        case .debugMenu:
            return false
        case .todayWidget:
            return false
        default:
            return true
        }
    }
}

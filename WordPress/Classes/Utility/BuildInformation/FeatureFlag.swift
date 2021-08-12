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
    case todayWidget
    case milestoneNotifications
    case bloggingReminders
    case siteIconCreator
    case editorOnboardingHelpMenu
    case unifiedCommentsAndNotificationsList
    case recommendAppToOthers

    /// Returns a boolean indicating if the feature is enabled
    var enabled: Bool {
        if let overriddenValue = FeatureFlagOverrideStore().overriddenValue(for: self) {
            return overriddenValue
        }

        switch self {
        case .jetpackDisconnect:
            return BuildConfiguration.current == .localDeveloper
        case .debugMenu:
            return BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest, .a8cPrereleaseTesting]
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
        case .todayWidget:
            return true
        case .milestoneNotifications:
            return true
        case .bloggingReminders:
            return true
        case .siteIconCreator:
            return BuildConfiguration.current != .appStore
        case .editorOnboardingHelpMenu:
            return BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest]
        case .unifiedCommentsAndNotificationsList:
            return true
        case .recommendAppToOthers:
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
        case .todayWidget:
            return "iOS 14 Today Widget"
        case .milestoneNotifications:
            return "Milestone notifications"
        case .bloggingReminders:
            return "Blogging Reminders"
        case .siteIconCreator:
            return "Site Icon Creator"
        case .editorOnboardingHelpMenu:
            return "Editor Onboarding Help Menu"
        case .unifiedCommentsAndNotificationsList:
            return "Unified List for Comments and Notifications"
        case .recommendAppToOthers:
            return "Recommend App to Others"
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

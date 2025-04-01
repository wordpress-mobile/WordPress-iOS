import BuildSettingsKit

/// FeatureFlag exposes a series of features to be conditionally enabled on
/// different builds.
@objc
public enum FeatureFlag: Int, CaseIterable {
    case signUp
    case customAppIcons
    case domainRegistration
    case selfHostedSites
    case whatsNew
    case qrCodeLogin
    case bloggingPrompts
    case jetpackDisconnect
    case siteIconCreator
    case betaSiteDesigns
    case commentModerationUpdate
    case compliancePopover
    case googleDomainsCard
    case voiceToContent
    case authenticateUsingApplicationPassword
    case newGutenberg
    case newGutenbergThemeStyles
    case newGutenbergPlugins
    case selfHostedSiteUserManagement
    case readerGutenbergCommentComposer
    case pluginManagementOverhaul

    /// Returns a boolean indicating if the feature is enabled.
    ///
    /// - warning: If the feature is unconditionally enabled, it doesn't mean
    /// that the flag can be removed. It provides a capability of conditionally
    /// disabling a feature if necessary. Use your best judgmenet.
    var enabled: Bool {
        if let overriddenValue = FeatureFlagOverrideStore().overriddenValue(for: self) {
            return overriddenValue
        }

        switch self {
        case .signUp:
            return true
        case .customAppIcons:
            return true
        case .domainRegistration:
            return AppConfiguration.isJetpack
        case .selfHostedSites:
            return true
        case .whatsNew:
            return true
        case .qrCodeLogin:
            return AppConfiguration.isJetpack
        case .bloggingPrompts:
            return AppConfiguration.isJetpack
        case .jetpackDisconnect:
            return BuildConfiguration.current == .debug
        case .siteIconCreator:
            return BuildConfiguration.current.isInternal
        case .betaSiteDesigns:
            return false
        case .commentModerationUpdate:
            return false
        case .compliancePopover:
            return true
        case .googleDomainsCard:
            return false
        case .voiceToContent:
            return AppConfiguration.isJetpack && BuildConfiguration.current.isInternal
        case .authenticateUsingApplicationPassword:
            return false
        case .newGutenberg:
            return false
        case .newGutenbergThemeStyles:
            return false
        case .newGutenbergPlugins:
            return false
        case .selfHostedSiteUserManagement:
            return false
        case .readerGutenbergCommentComposer:
            return false
        case .pluginManagementOverhaul:
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
public class Feature: NSObject {
    /// Returns a boolean indicating if the feature is enabled
    @objc public static func enabled(_ feature: FeatureFlag) -> Bool {
        return feature.enabled
    }
}

extension FeatureFlag {
    /// Descriptions used to display the feature flag override menu in debug builds
    public var description: String {
        return switch self {
        case .signUp: "Sign Up"
        case .customAppIcons: "Custom App Icons"
        case .domainRegistration: "Domain Registration"
        case .selfHostedSites: "Self-Hosted Sites"
        case .whatsNew: "What's New"
        case .qrCodeLogin: "QR Code Login"
        case .bloggingPrompts: "Blogging Prompts"
        case .jetpackDisconnect: "Jetpack disconnect"
        case .siteIconCreator: "Site Icon Creator"
        case .betaSiteDesigns: "Fetch Beta Site Designs"
        case .commentModerationUpdate: "Comments Moderation Update"
        case .compliancePopover: "Compliance Popover"
        case .googleDomainsCard: "Google Domains Promotional Card"
        case .voiceToContent: "Voice to Content"
        case .authenticateUsingApplicationPassword: "Application Passwords for self-hosted sites"
        case .newGutenberg: "Experimental Block Editor"
        case .newGutenbergThemeStyles: "Experimental Block Editor Styles"
        case .newGutenbergPlugins: "Experimental Block Editor Plugins"
        case .selfHostedSiteUserManagement: "Self-hosted Site User Management"
        case .pluginManagementOverhaul: "Plugin Management Overhaul"
        case .readerGutenbergCommentComposer: "Gutenberg Comment Composer"
        }
    }
}

extension FeatureFlag: OverridableFlag {

    var originalValue: Bool {
        return enabled
    }

    var key: String {
        return "ff-override-\(String(describing: self))"
    }
}

extension FeatureFlag: RolloutConfigurableFlag {
    /// Represents the percentage of users to roll the flag out to.
    ///
    /// To set a percentage rollout, return a value between 0.0 and 1.0.
    /// If a percentage rollout isn't applicable for the flag, return nil.
    ///
    var rolloutPercentage: Double? {
        return nil
    }
}

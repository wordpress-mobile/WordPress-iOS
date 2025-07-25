import BuildSettingsKit
import Foundation

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
    case allowApplicationPasswords
    case newGutenbergThemeStyles
    case selfHostedSiteUserManagement
    case readerGutenbergCommentComposer
    case pluginManagementOverhaul
    case nativeJetpackConnection
    case newsletterSubscribers

    /// Returns a boolean indicating if the feature is enabled.
    ///
    /// - warning: If the feature is unconditionally enabled, it doesn't mean
    /// that the flag can be removed. It provides a capability of conditionally
    /// disabling a feature if necessary. Use your best judgmenet.
    var enabled: Bool {
        if let overriddenValue = FeatureFlagOverrideStore().overriddenValue(for: self) {
            return overriddenValue
        }

        let app = BuildSettings.current.brand

        switch self {
        case .signUp:
            return true
        case .customAppIcons:
            return true
        case .domainRegistration:
            return app == .jetpack || app == .reader
        case .selfHostedSites:
            return app != .reader
        case .whatsNew:
            return true
        case .qrCodeLogin:
            return app == .jetpack
        case .bloggingPrompts:
            return app == .jetpack || app == .reader
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
            return app == .jetpack && BuildConfiguration.current.isInternal
        case .allowApplicationPasswords:
            return false
        case .newGutenbergThemeStyles:
            return false
        case .selfHostedSiteUserManagement:
            return false
        case .readerGutenbergCommentComposer:
            return false
        case .pluginManagementOverhaul:
            return false
        case .nativeJetpackConnection:
            return BuildConfiguration.current == .debug
        case .newsletterSubscribers:
            return true
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
        case .allowApplicationPasswords: "Allow creating Application Passwords"
        case .newGutenbergThemeStyles: "Experimental Block Editor Styles"
        case .selfHostedSiteUserManagement: "Self-hosted Site User Management"
        case .pluginManagementOverhaul: "Plugin Management Overhaul"
        case .readerGutenbergCommentComposer: "Gutenberg Comment Composer"
        case .nativeJetpackConnection: "Native Jetpack Connection"
        case .newsletterSubscribers: "Newsletter Subscribers"
        }
    }
}

extension FeatureFlag: OverridableFlag {

    var originalValue: Bool {
        return enabled
    }

    var key: String {
        let key: String
        switch self {
        case .allowApplicationPasswords:
            // This feature toggle description is already shipped and used in the production.
            // We want to keep using the same key, but change the description.
            key = "Application Passwords for self-hosted sites"
        default:
            key = String(describing: self)
        }
        return "ff-override-\(key)"
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

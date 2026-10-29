import Foundation
import BuildSettingsKit

@objc
public enum RemoteFeatureFlag: Int, CaseIterable {
    case blaze
    case blazeManageCampaigns
    case wordPressIndividualPluginSupport
    case pagesDashboardCard
    case activityLogDashboardCard
    case bloggingPromptsSocial
    case siteEditorMVP
    case contactSupportChatbot
    case domainManagement
    case dynamicDashboardCards
    case plansInSiteCreation
    case inAppRating
    case siteMonitoring
    case inAppUpdates
    case gravatarQuickEditor
    case dotComWebLogin
    case newGutenberg
    case newGutenbergPlugins
    case statsAds
    case readerInWordPressApp

    var defaultValue: Bool {
        let app = BuildSettings.current.brand

        switch self {
        case .blaze:
            return false
        case .blazeManageCampaigns:
            return false
        case .wordPressIndividualPluginSupport:
            return AppConfiguration.isWordPress
        case .pagesDashboardCard:
            return false
        case .activityLogDashboardCard:
            return false
        case .bloggingPromptsSocial:
            return AppConfiguration.isJetpack
        case .siteEditorMVP:
            return true
        case .contactSupportChatbot:
            return false
        case .domainManagement:
            return false
        case .dynamicDashboardCards:
            return false
        case .plansInSiteCreation:
            return false
        case .inAppRating:
            return false
        case .siteMonitoring:
            return false
        case .inAppUpdates:
            return false
        case .gravatarQuickEditor:
            return BuildConfiguration.current.isInternal
        case .dotComWebLogin:
            return false
        case .newGutenberg:
            return app == .reader
        case .newGutenbergPlugins:
            return false
        case .statsAds:
            return false
        case .readerInWordPressApp:
            return false
        }
    }

    /// This key must match the server-side one for remote feature flagging
    var remoteKey: String {
        switch self {
        case .blaze:
            return "blaze"
        case .blazeManageCampaigns:
            return "blaze_manage_campaigns"
        case .wordPressIndividualPluginSupport:
            return "wp_individual_plugin_overlay"
        case .pagesDashboardCard:
            return "dashboard_card_pages"
        case .activityLogDashboardCard:
            return "dashboard_card_activity_log"
        case .bloggingPromptsSocial:
            return "blogging_prompts_social_enabled"
        case .siteEditorMVP:
            return "site_editor_mvp"
        case .contactSupportChatbot:
            return "contact_support_chatbot"
        case .domainManagement:
            return "domain_management"
        case .dynamicDashboardCards:
            return "dynamic_dashboard_cards"
        case .plansInSiteCreation:
            return "plans_in_site_creation"
        case .inAppRating:
            return "in_app_rating_and_feedback"
        case .siteMonitoring:
            return "site_monitoring"
        case .inAppUpdates:
            return "in_app_updates"
        case .gravatarQuickEditor:
            return "gravatar_quick_editor"
        case .dotComWebLogin:
            return "jp_wpcom_web_login"
        case .newGutenberg:
            return "gutenberg_kit"
        case .newGutenbergPlugins:
            return "gutenberg_kit_plugins"
        case .statsAds:
            return "stats_ads"
        case .readerInWordPressApp:
            return "wordpress_ios_reader"
        }
    }

    public var description: String {
        switch self {
        case .blaze:
            return "Blaze"
        case .blazeManageCampaigns:
            return "Blaze Manage Campaigns"
        case .wordPressIndividualPluginSupport:
            return "Jetpack Individual Plugin Support for WordPress"
        case .pagesDashboardCard:
            return "Pages Dashboard Card"
        case .activityLogDashboardCard:
            return "Activity Log Dashboard Card"
        case .bloggingPromptsSocial:
            return "Blogging Prompts Social"
        case .siteEditorMVP:
            return "Site Editor MVP"
        case .contactSupportChatbot:
            return "Contact Support via DocsBot"
        case .domainManagement:
            return "Domain Management"
        case .dynamicDashboardCards:
            return "Dynamic Dashboard Cards"
        case .plansInSiteCreation:
            return "Plans in Site Creation"
        case .inAppRating:
            return "In-App Rating and Feedback"
        case .siteMonitoring:
            return "Site Monitoring"
        case .inAppUpdates:
            return "In-App Updates"
        case .gravatarQuickEditor:
            return "Gravatar Quick Editor"
        case .dotComWebLogin:
            return "Log in to WordPress.com from web browser"
        case .newGutenberg:
            return "Experimental Block Editor"
        case .newGutenbergPlugins:
            return "Experimental Block Editor Plugins"
        case .statsAds:
            return "Stats Ads Tab"
        case .readerInWordPressApp:
            return "Reader in WordPress App"
        }
    }

    /// If the flag is overridden, the overridden value is returned.
    /// If the flag exists in the local cache, the current value will be returned.
    /// If the flag is not overridden and does not exist in the local cache, the compile-time default will be returned.
    func enabled(
        using remoteStore: RemoteFeatureFlagStore = RemoteFeatureFlagStore(),
        overrideStore: FeatureFlagOverrideStore = FeatureFlagOverrideStore()
    ) -> Bool {
        if let overriddenValue = overrideStore.overriddenValue(for: self) {
            return overriddenValue
        }
        if let remoteValue = remoteStore.value(for: remoteKey) { // The value may not be in the cache if this is the first run
            return remoteValue
        }
        DDLogInfo("🚩 Unable to resolve remote feature flag: \(description). Returning compile-time default.")
        return defaultValue
    }
}

extension RemoteFeatureFlag: OverridableFlag {
    var key: String {
        "ff-override-\(String(describing: self))"
    }

    var originalValue: Bool {
        enabled()
    }

    var canOverride: Bool {
        true
    }
}

/// Objective-C bridge for RemoteFeatureFlag.
///
/// Since we can't expose properties on Swift enums we use a class instead
public class RemoteFeature: NSObject {
    /// Returns a boolean indicating if the feature is enabled
    @objc public static func enabled(_ feature: RemoteFeatureFlag) -> Bool {
        feature.enabled()
    }
}

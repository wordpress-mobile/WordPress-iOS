import Foundation

@objc
enum RemoteFeatureFlag: Int, CaseIterable {
    case jetpackFeaturesRemovalPhaseOne
    case jetpackFeaturesRemovalPhaseTwo
    case jetpackFeaturesRemovalPhaseThree
    case jetpackFeaturesRemovalPhaseFour
    case jetpackFeaturesRemovalPhaseNewUsers
    case jetpackFeaturesRemovalPhaseSelfHosted
    case jetpackFeaturesRemovalStaticPosters
    case jetpackMigrationPreventDuplicateNotifications
    case wordPressSupportForum
    case blaze
    case wordPressIndividualPluginSupport
    case directDomainsPurchaseDashboardCard

    var defaultValue: Bool {
        switch self {
        case .jetpackMigrationPreventDuplicateNotifications:
            return true
        case .jetpackFeaturesRemovalPhaseOne:
            return false
        case .jetpackFeaturesRemovalPhaseTwo:
            return false
        case .jetpackFeaturesRemovalPhaseThree:
            return false
        case .jetpackFeaturesRemovalPhaseFour:
            return false
        case .jetpackFeaturesRemovalPhaseNewUsers:
            return false
        case .jetpackFeaturesRemovalPhaseSelfHosted:
            return false
        case .jetpackFeaturesRemovalStaticPosters:
            return false
        case .wordPressSupportForum:
            return true
        case .blaze:
            return false
        case .wordPressIndividualPluginSupport:
            return AppConfiguration.isWordPress
        case .directDomainsPurchaseDashboardCard:
            return false
        }
    }

    /// This key must match the server-side one for remote feature flagging
    var remoteKey: String {
        switch self {
        case .jetpackFeaturesRemovalPhaseOne:
            return "jp_removal_one"
        case .jetpackFeaturesRemovalPhaseTwo:
            return "jp_removal_two"
        case .jetpackFeaturesRemovalPhaseThree:
            return "jp_removal_three"
        case .jetpackFeaturesRemovalPhaseFour:
            return "jp_removal_four"
        case .jetpackFeaturesRemovalPhaseNewUsers:
            return "jp_removal_new_users"
        case .jetpackFeaturesRemovalPhaseSelfHosted:
            return "jp_removal_self_hosted"
        case .jetpackFeaturesRemovalStaticPosters:
            return "jp_removal_static_posters"
        case .jetpackMigrationPreventDuplicateNotifications:
            return "prevent_duplicate_notifs_remote_field"
        case .wordPressSupportForum:
            return "wordpress_support_forum_remote_field"
        case .blaze:
            return "blaze"
        case .wordPressIndividualPluginSupport:
            return "wp_individual_plugin_overlay"
        case .directDomainsPurchaseDashboardCard:
            return "direct_domain_purchase_dashboard_card"
        }
    }

    var description: String {
        switch self {
        case .jetpackMigrationPreventDuplicateNotifications:
            return "Jetpack Migration prevent duplicate WordPress app notifications when Jetpack is installed"
        case .jetpackFeaturesRemovalPhaseOne:
            return "Jetpack Features Removal Phase One"
        case .jetpackFeaturesRemovalPhaseTwo:
            return "Jetpack Features Removal Phase Two"
        case .jetpackFeaturesRemovalPhaseThree:
            return "Jetpack Features Removal Phase Three"
        case .jetpackFeaturesRemovalPhaseFour:
            return "Jetpack Features Removal Phase Four"
        case .jetpackFeaturesRemovalPhaseNewUsers:
            return "Jetpack Features Removal Phase For New Users"
        case .jetpackFeaturesRemovalPhaseSelfHosted:
            return "Jetpack Features Removal Phase For Self-Hosted Sites"
        case .jetpackFeaturesRemovalStaticPosters:
            return "Jetpack Features Removal Static Screens Phase"
        case .wordPressSupportForum:
            return "Provide support through a forum"
        case .blaze:
            return "Blaze"
        case .wordPressIndividualPluginSupport:
            return "Jetpack Individual Plugin Support for WordPress"
        case .directDomainsPurchaseDashboardCard:
            return "Direct Domains Purchase Dashboard Card"
        }
    }

    /// If the flag is overridden, the overridden value is returned.
    /// If the flag exists in the local cache, the current value will be returned.
    /// If the flag is not overridden and does not exist in the local cache, the compile-time default will be returned.
    func enabled(using remoteStore: RemoteFeatureFlagStore = RemoteFeatureFlagStore(),
                 overrideStore: FeatureFlagOverrideStore = FeatureFlagOverrideStore()) -> Bool {
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
    var originalValue: Bool {
        return enabled()
    }

    var canOverride: Bool {
        true
    }
}

/// Objective-C bridge for RemoteFeatureFlag.
///
/// Since we can't expose properties on Swift enums we use a class instead
class RemoteFeature: NSObject {
    /// Returns a boolean indicating if the feature is enabled
    @objc static func enabled(_ feature: RemoteFeatureFlag) -> Bool {
        return feature.enabled()
    }
}

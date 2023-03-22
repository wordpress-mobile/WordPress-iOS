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
        }
    }

    func enabled(using remoteStore: RemoteFeatureFlagStore = RemoteFeatureFlagStore(),
                 overrideStore: FeatureFlagOverrideStore = FeatureFlagOverrideStore()) -> Bool {
        if let overriddenValue = overrideStore.overriddenValue(for: self) {
            return overriddenValue
        }
        guard let remoteValue = remoteStore.value(for: remoteKey) else { // The value may not be in the cache if this is the first run
            DDLogInfo("🚩 Unable to resolve remote feature flag: \(description). Returning compile-time default.")
            return defaultValue
        }
        return remoteValue
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

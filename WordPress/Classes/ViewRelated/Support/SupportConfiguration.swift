import Foundation

enum SupportConfiguration {
    case zendesk
    case forum

    private static func hasSiteWithPaidPlan() -> Bool {
        let allBlogs = (try? BlogQuery().blogs(in: ContextManager.sharedInstance().mainContext)) ?? []
        return allBlogs.contains { $0.hasPaidPlan }
    }

    static func current(
        featureFlagStore: RemoteFeatureFlagStore = RemoteFeatureFlagStore(),
        isWordPress: Bool = AppConfiguration.isWordPress,
        zendeskEnabled: Bool = ZendeskUtils.zendeskEnabled,
        hasPaidPlan: Bool = hasSiteWithPaidPlan()
    ) -> SupportConfiguration {
        guard zendeskEnabled else {
            return .forum
        }

        if isWordPress && !hasPaidPlan && featureFlagStore.value(for: FeatureFlag.wordPressSupportForum) {
            return .forum
        } else {
            return .zendesk
        }
    }

    static func isMigrationCardEnabled(
        isJetpack: Bool = AppConfiguration.isJetpack,
        migrationState: MigrationState = UserPersistentStoreFactory.instance().jetpackContentMigrationState
    ) -> Bool {
        return isJetpack && migrationState == .completed
    }
}

@objc class SupportConfigurationObjC: NSObject {
    @objc static var isStartOverSupportEnabled: Bool {
        return SupportConfiguration.current() == .zendesk
    }
}

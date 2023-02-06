import Foundation

enum SupportConfiguration {
    case zendesk
    case forum

    static func current(
        featureFlagStore: RemoteFeatureFlagStore = RemoteFeatureFlagStore(),
        isWordPress: Bool = AppConfiguration.isWordPress,
        zendeskEnabled: Bool = ZendeskUtils.zendeskEnabled
    ) -> SupportConfiguration {
        guard zendeskEnabled else {
            return .forum
        }

        if isWordPress && featureFlagStore.value(for: FeatureFlag.wordPressSupportForum) {
            return .forum
        } else {
            return .zendesk
        }
    }
}

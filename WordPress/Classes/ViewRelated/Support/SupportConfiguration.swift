import Foundation
import WordPressShared

enum SupportConfiguration {
    case zendesk
    case forum

    static func current(
        isWordPress: Bool = AppConfiguration.isWordPress,
        zendeskEnabled: Bool = ZendeskUtils.zendeskEnabled) -> SupportConfiguration {
        guard zendeskEnabled else {
            return .forum
        }

        if isWordPress {
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

    static var isStartOverSupportEnabled: Bool {
        SupportConfiguration.current() == .zendesk
    }
}

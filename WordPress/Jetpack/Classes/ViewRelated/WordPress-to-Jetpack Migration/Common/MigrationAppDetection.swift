import Foundation

enum WordPressInstallationState {
    case wordPressNotInstalled
    case wordPressInstalledNotMigratable
    case wordPressInstalledAndMigratable
}

struct MigrationAppDetection {

    static func getWordPressInstallationState() -> WordPressInstallationState {
        if UIApplication.shared.canOpen(app: .wordpressMigrationV1) {
            return .wordPressInstalledAndMigratable
        }

        if UIApplication.shared.canOpen(app: .wordpress) {
            return .wordPressInstalledNotMigratable
        }

        return .wordPressNotInstalled
    }
}

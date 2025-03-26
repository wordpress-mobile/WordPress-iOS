import Foundation

enum WordPressInstallationState {
    case wordPressNotInstalled
    case wordPressInstalledNotMigratable
    case wordPressInstalledAndMigratable

    var isWordPressInstalled: Bool {
        return self != .wordPressNotInstalled
    }
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

    static var isCounterpartAppInstalled: Bool {
        let scheme: AppScheme = AppConfiguration.isJetpack ? .wordpress : .jetpack
        return UIApplication.shared.canOpen(app: scheme)
    }
}

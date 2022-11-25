import Foundation

extension MigrationSuccessCardView {

    // TODO: Perhaps this logic should move to another location
    @objc static var shouldShowMigrationSuccessCard: Bool {
        let migrationCompleted = false // Refactor to UserDefaults.standard.bool("migration-ready")
        let wordPressAppExists = MigrationHelper.isWordPressInstalled()
        return migrationCompleted && wordPressAppExists
    }
}

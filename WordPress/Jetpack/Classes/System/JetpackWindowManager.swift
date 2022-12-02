import Combine
import Foundation

class JetpackWindowManager: WindowManager {
    /// receives migration flow updates in order to dismiss it when needed.
    private var cancellable: AnyCancellable?

    var shouldImportMigrationData: Bool {
        return !AccountHelper.isLoggedIn && !UserPersistentStoreFactory.instance().isJPContentImportComplete
    }

    override func showUI(for blog: Blog?) {
        // If the user is logged in and has blogs sync'd to their account
        if AccountHelper.isLoggedIn && AccountHelper.hasBlogs {
            showAppUI(for: blog)
            return
        }

        guard AccountHelper.isLoggedIn else {
            shouldImportMigrationData ? importAndShowMigrationContent(blog) : showSignInUI()
            return
        }
        // If the user doesn't have any blogs, but they're still logged in, log them out
        // the `logOutDefaultWordPressComAccount` method will trigger the `showSignInUI` automatically
        AccountHelper.logOutDefaultWordPressComAccount()
    }

    func importAndShowMigrationContent(_ blog: Blog? = nil) {
        DataMigrator().importData() { [weak self] result in
            guard let self else {
                return
            }

            switch result {
            case .success:
                UserPersistentStoreFactory.instance().isJPContentImportComplete = true
                NotificationCenter.default.post(name: .WPAccountDefaultWordPressComAccountChanged, object: self)
                self.showMigrationUIIfNeeded(blog)
                self.sendMigrationEmail()
            case .failure(let error):
                self.handleMigrationFailure(error)
            }
        }
    }
}

// MARK: - Private Helpers

private extension JetpackWindowManager {

    var shouldShowMigrationUI: Bool {
        return FeatureFlag.contentMigration.enabled && AccountHelper.isLoggedIn
    }

    /// Checks whether the WordPress app supports the custom scheme meant to disable notifications.
    /// Since the scheme is added in 21.3, we can be pretty sure that the WP version also supports migration.
    var isCompatibleWordPressAppPresent: Bool {
        JetpackNotificationMigrationService.shared.isMigrationSupported
    }

    func sendMigrationEmail() {
        Task {
            let service = try? MigrationEmailService()
            try? await service?.sendMigrationEmail()
        }
    }

    func showMigrationUIIfNeeded(_ blog: Blog?) {
        guard shouldShowMigrationUI else {
            return
        }

        let container = MigrationDependencyContainer()
        cancellable = container.migrationCoordinator.$currentStep
            .receive(on: DispatchQueue.main)
            .sink { [weak self] step in
                guard step == .dismiss else {
                    return
                }
                self?.switchToAppUI(for: blog)
            }
        self.show(container.makeInitialViewController())
    }

    func switchToAppUI(for blog: Blog?) {
        cancellable = nil
        showAppUI(for: blog)
    }

    func handleMigrationFailure(_ error: DataMigrationError) {
        guard case .dataNotReadyToImport = error,
              isCompatibleWordPressAppPresent else {
            showSignInUI()
            return
        }

        // TODO: Show UI that provides WP pre-flight action.

    }
}

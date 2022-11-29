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
            if shouldImportMigrationData {
                importAndShowMigrationContent(blog) { [weak self] in
                    self?.showSignInUI()
                }
            } else {
                showAppUI(for: blog)
            }
            return
        }
        // If the user doesn't have any blogs, but they're still logged in, log them out
        // the `logOutDefaultWordPressComAccount` method will trigger the `showSignInUI` automatically
        AccountHelper.logOutDefaultWordPressComAccount()
    }

    func importAndShowMigrationContent(_ blog: Blog?, failureCompletion: (() -> ())?) {
        DataMigrator().importData() { [weak self] result in
            guard let self else {
                return
            }

            switch result {
            case .success:
                UserPersistentStoreFactory.instance().isJPContentImportComplete = true
                NotificationCenter.default.post(name: .WPAccountDefaultWordPressComAccountChanged, object: nil)
                self.showMigrationUIIfNeeded(blog)
            case .failure:
                failureCompletion?()
            }
        }
    }

    private func showMigrationUIIfNeeded(_ blog: Blog?) {
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

    private func switchToAppUI(for blog: Blog?) {
        cancellable = nil
        showAppUI(for: blog)
    }

    private var shouldShowMigrationUI: Bool {
        return FeatureFlag.contentMigration.enabled && AccountHelper.isLoggedIn
    }
}

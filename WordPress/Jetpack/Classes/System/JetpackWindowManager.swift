import Combine
import Foundation

class JetpackWindowManager: WindowManager {
    /// receives migration flow updates in order to dismiss it when needed.
    private var cancellable: AnyCancellable?

    /// Migration events tracking
    private let migrationTracker = MigrationAnalyticsTracker()

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
            self.migrationTracker.trackContentImportEligibility(eligible: shouldImportMigrationData)
            shouldImportMigrationData ? importAndShowMigrationContent(blog) : showSignInUI()
            return
        }

        // If the user doesn't have any blogs, but they're still logged in, log them out
        // the `logOutDefaultWordPressComAccount` method will trigger the `showSignInUI` automatically
        AccountHelper.logOutDefaultWordPressComAccount()
    }

    func importAndShowMigrationContent(_ blog: Blog? = nil) {
        self.migrationTracker.trackWordPressMigrationEligibility()

        DataMigrator().importData() { [weak self] result in
            guard let self else {
                return
            }

            switch result {
            case .success:
                self.migrationTracker.trackContentImportSucceeded()
                UserPersistentStoreFactory.instance().isJPContentImportComplete = true
                NotificationCenter.default.post(name: .WPAccountDefaultWordPressComAccountChanged, object: self)
                self.showMigrationUIIfNeeded(blog)
                self.sendMigrationEmail()
            case .failure(let error):
                self.migrationTracker.trackContentImportFailed(reason: error.localizedDescription)
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

    var isCompatibleWordPressAppPresent: Bool {
        MigrationAppDetection.getWordPressInstallationState() == .wordPressInstalledAndMigratable
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

    /// Shown when the WordPress pre-flight process hasn't ran, but WordPress is installed.
    /// Note: We don't know if the user has ever logged into WordPress at this point, only
    /// that they have a version compatible with migrating.
    /// - Parameter schemeUrl: Deep link URL used to open the WordPress app
    func showLoadWordPressUI(schemeUrl: URL) {
        let actions = MigrationLoadWordPressViewModel.Actions()
        let loadWordPressViewModel = MigrationLoadWordPressViewModel(actions: actions)
        let loadWordPressViewController = MigrationLoadWordPressViewController(viewModel: loadWordPressViewModel)
        actions.primary = {
            UIApplication.shared.open(schemeUrl)
        }
        actions.secondary = { [weak self] in
            loadWordPressViewController.dismiss(animated: true) {
                self?.showSignInUI()
            }
        }
        self.show(loadWordPressViewController)
    }

    func handleMigrationFailure(_ error: DataMigrationError) {
        guard
            case .dataNotReadyToImport = error,
            isCompatibleWordPressAppPresent,
            let schemeUrl = URL(string: "\(AppScheme.wordpressMigrationV1.rawValue)\(WordPressExportRoute().path.removingPrefix("/"))")
        else {
            showSignInUI()
            return
        }

        /// WordPress is a compatible version for migrations, but needs to be loaded to prepare the data
        showLoadWordPressUI(schemeUrl: schemeUrl)
    }
}

import Combine
import Foundation

class JetpackWindowManager: WindowManager {
    /// receives migration flow updates in order to dismiss it when needed.
    private var cancellable: AnyCancellable?

    /// Migration events tracking
    private let migrationTracker = MigrationAnalyticsTracker()

    var shouldImportMigrationData: Bool {
        return FeatureFlag.contentMigration.enabled
        && !UserPersistentStoreFactory.instance().isJPMigrationFlowComplete
    }

    override func showUI(for blog: Blog?, animated: Bool = true) {
        // Show migration flow if eligible
        let shouldShowMigrationFlow = self.shouldImportMigrationData
        let isLoggedIn = AccountHelper.isLoggedIn
        if shouldShowMigrationFlow {
            AccountHelper.isLoggedIn ? self.showMigrationUIIfNeeded(blog) : self.importAndShowMigrationContent(blog)
            return
        }

        // Show App UI if user is logged in
        if AccountHelper.isLoggedIn {
            self.showAppUI(for: blog)
            return
        }

        // Show Sign In UI if previous conditions are false
        self.showSignInUI()
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
                NotificationCenter.default.post(name: .WPAccountDefaultWordPressComAccountChanged, object: self)
                self.showMigrationUIIfNeeded(blog)
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

    /// Checks whether the WordPress app has previously failed to export user content.
    var hasFailedExportAttempts: Bool {
        ContentMigrationCoordinator.shared.previousMigrationError != nil
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
        let loadWordPressViewController = MigrationLoadWordPressViewController(
            viewModel: loadWordPressViewModel,
            tracker: migrationTracker
        )
        actions.primary = { [weak self] in
            self?.migrationTracker.track(.loadWordPressScreenOpenTapped)
            UIApplication.shared.open(schemeUrl)
        }
        actions.secondary = { [weak self, weak loadWordPressViewController] in
            self?.migrationTracker.track(.loadWordPressScreenNoThanksTapped)
            loadWordPressViewController?.dismiss(animated: true) {
                self?.showSignInUI()
            }
        }
        self.show(loadWordPressViewController)
    }

    /// Determine how to handle the error when the migration fails.
    ///
    /// Show the loadWordPress path when:
    ///   - A compatible WordPress app version exists,
    ///   - There's no data to import, and
    ///   - There's no data because the export was never triggered, not because WP tried to export and failed.
    ///
    /// Otherwise, show the sign in flow.
    ///
    /// - Parameter error: Error object from the data migration process.
    func handleMigrationFailure(_ error: DataMigrationError) {
        guard
            isCompatibleWordPressAppPresent,
            case .dataNotReadyToImport = error,
            !hasFailedExportAttempts,
            let schemeUrl = URL(string: "\(AppScheme.wordpressMigrationV1.rawValue)\(WordPressExportRoute().path.removingPrefix("/"))")
        else {
            showSignInUI()
            return
        }

        /// WordPress is a compatible version for migrations, but needs to be loaded to prepare the data
        showLoadWordPressUI(schemeUrl: schemeUrl)
    }
}

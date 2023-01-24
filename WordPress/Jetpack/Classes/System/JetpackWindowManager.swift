import Combine
import Foundation

class JetpackWindowManager: WindowManager {
    /// receives migration flow updates in order to dismiss it when needed.
    private var cancellable: AnyCancellable?

    /// Migration events tracking
    private let migrationTracker = MigrationAnalyticsTracker()

    var shouldImportMigrationData: Bool {
        return FeatureFlag.contentMigration.enabled
        && !AccountHelper.isLoggedIn
        && !UserPersistentStoreFactory.instance().isJPContentImportComplete
    }

    override func showUI(for blog: Blog?, animated: Bool = true) {
        if AccountHelper.isLoggedIn {
            showAppUI(for: blog)
            return
        }

        guard FeatureFlag.contentMigration.enabled else {
            showSignInUI()
            return
        }

        self.migrationTracker.trackContentImportEligibility(eligible: shouldImportMigrationData)
        shouldImportMigrationData ? importAndShowMigrationContent(blog) : showSignInUI()
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

    /// Checks whether the WordPress app has previously failed to export user content.
    var hasFailedExportAttempts: Bool {
        ContentMigrationCoordinator.shared.previousMigrationError != nil
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
            performSafeRootNavigation { [weak self] in
                self?.showSignInUI()
            }
            return
        }

        /// WordPress is a compatible version for migrations, but needs to be loaded to prepare the data
        performSafeRootNavigation { [weak self] in
            self?.showLoadWordPressUI(schemeUrl: schemeUrl)
        }
    }

    /// This method takes care of preventing screens being abruptly replaced.
    ///
    /// Since the import method is called whenever the app is foregrounded, we want to make sure that
    /// any root view controller replacements only happen where it is "allowed":
    ///
    ///   1. When there's no root view controller yet, or
    ///   2. When the Load WordPress screen is shown.
    ///
    /// Note: We should remove this method when the migration phase is concluded and we no longer need
    /// to perfom the migration.
    ///
    /// - Parameter navigationClosure: The closure containing logic that eventually calls the `show` method.
    func performSafeRootNavigation(with navigationClosure: @escaping () -> Void) {
        switch rootViewController {
        case .none:
            // we can perform the navigation directly when there's no root view controller yet.
            navigationClosure()
        case .some(let viewController) where viewController is MigrationLoadWordPressViewController:
            // allow the Load WordPress view to be replaced in case the migration process fails.
            viewController.dismiss(animated: true, completion: navigationClosure)
        default:
            // do nothing when another root view controller is already displayed.
            break
        }
    }
}

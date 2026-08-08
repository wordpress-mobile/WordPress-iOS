import Combine
import Foundation
import WordPressData
import WordPressShared

class JetpackWindowManager: WindowManager {

    /// Receives migration flow updates in order to dismiss it when needed.
    private var cancellable: AnyCancellable?

    /// Reference to the presented migration view controller.
    ///
    /// Used to prevent a new migration view controller instance to be presented if
    /// an existing one is already presented.
    private weak var migrationViewController: UIViewController?

    /// Migration events tracking
    private let migrationTracker = MigrationAnalyticsTracker()

    override func showUI(for blog: Blog?, animated: Bool = true) {
        // Show migration flow if eligible
        let migrationStarted = startMigrationFlowIfNeeded(blog)
        if migrationStarted {
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
}

// MARK: - Migration Related Properties and Methods

extension JetpackWindowManager {

    /// Starts the migration flow if `shouldStartMigrationFlow` is true.
    ///
    /// Keep in mind that starting the Migration Flow doesn't mean it is guaranteed the Migration UI will show up.
    /// The Migration could fail during the content import phase, and the UI won't show up.
    ///
    /// - Returns: Returns a boolean indicating whether the Migration Flow has started or not.
    @discardableResult func startMigrationFlowIfNeeded(_ blog: Blog? = nil) -> Bool {
        let shouldStartMigrationFlow = self.shouldStartMigrationFlow

        let params = MigrationAnalyticsTracker.ContentImportEventParams(
            eligible: shouldStartMigrationFlow,
            featureFlagEnabled: true,
            compatibleWordPressInstalled: isCompatibleWordPressAppPresent,
            migrationState: UserPersistentStoreFactory.instance().jetpackContentMigrationState,
            loggedIn: AccountHelper.isLoggedIn
        )

        self.migrationTracker.trackContentImportEligibility(params: params)

        guard shouldStartMigrationFlow else {
            return false
        }

        self.importAndShowMigrationContent(blog)
        return true
    }
}

// MARK: Private Helpers

private extension JetpackWindowManager {

    /// Checks whether the migration flow should start or not.
    ///
    /// This flag is `False` if a compatible WordPress app is not installed or the `contentMigration` feature flag is disabled.
    ///
    /// Otherwise, it is `True` when the following conditions are fulfilled:
    ///
    ///  1. User is not logged in and the migration is not complete.
    ///  2. Or, User is logged in and the migration has started but still in progress. This scenario could happen if the migration flow starts but interrupted mid flow.
    ///
    var shouldStartMigrationFlow: Bool {
        guard isCompatibleWordPressAppPresent else {
            return false
        }
        let migrationState = UserPersistentStoreFactory.instance().jetpackContentMigrationState
        let loggedIn = AccountHelper.isLoggedIn
        return loggedIn ? migrationState == .inProgress : migrationState != .completed
    }

    /// Flag indicating whether a compatible WordPress app is installed
    var isCompatibleWordPressAppPresent: Bool {
        MigrationAppDetection.getWordPressInstallationState() == .wordPressInstalledAndMigratable
    }

    func importAndShowMigrationContent(_ blog: Blog? = nil) {
        self.migrationTracker.trackWordPressMigrationEligibility()

        // If the user is already logged in, this could mean they
        // attempted the migration before but it was interrupted mid-flow.
        //
        // This could happen if the user starts the migration flow
        // then closes the app in the Notification step for example.
        //
        // In this case, no need to import the data because it already exists.
        if AccountHelper.isLoggedIn {
            self.showMigrationUI(blog)
            return
        }

        // If the user is not logged in, then we should import the WordPress content.
        //
        // Once the import is done, `AccountHelper.isLoggedIn` is true and we can safely show
        // the Welcome screen.
        DataMigrator().importData() { [weak self] result in
            guard let self else {
                return
            }
            switch result {
            case .success:
                self.migrationTracker.trackContentImportSucceeded()
                NotificationCenter.default.post(name: .wpAccountDefaultWordPressComAccountChanged, object: self)
                self.showMigrationUI(blog)
            case .failure(let error):
                self.migrationTracker.trackContentImportFailed(reason: error.localizedDescription)
                self.handleMigrationFailure()
            }
        }
    }

    func showMigrationUI(_ blog: Blog?) {
        // Check if an existing instance of the migration screen is not already presented
        guard migrationViewController == nil || migrationViewController?.view?.window == nil else {
            return
        }
        let container = MigrationDependencyContainer()
        cancellable = container.migrationCoordinator.$currentStep
            .receive(on: DispatchQueue.main)
            .sink { [weak self] step in
                guard let self, step == .dismiss else {
                    return
                }
                self.switchToAppUI(for: blog)
            }
        let destination = container.makeInitialViewController()
        self.migrationViewController = destination
        self.show(destination)
    }

    func switchToAppUI(for blog: Blog?) {
        cancellable = nil
        showAppUI(for: blog)
    }

    /// Shows the sign in flow when the content import fails.
    ///
    /// The import is attempted whenever the app is foregrounded, so only
    /// navigate when there is no root view controller yet. This prevents
    /// whatever screen the user is looking at from being abruptly replaced.
    func handleMigrationFailure() {
        guard rootViewController == nil else {
            return
        }
        showSignInUI()
    }
}

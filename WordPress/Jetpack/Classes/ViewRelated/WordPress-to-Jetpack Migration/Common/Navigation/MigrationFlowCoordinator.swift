import Combine
import UserNotifications

/// Coordinator for the migration to jetpack flow
final class MigrationFlowCoordinator: ObservableObject {

    // MARK: - Dependencies

    private let migrationEmailService: MigrationEmailService?
    private let userPersistentRepository: UserPersistentRepository

    // MARK: - Properties

    // Beware that changes won't be published on the main thread,
    // so always make sure to return to the main thread for UI updates
    // related to this property.
    @Published private(set) var currentStep = MigrationStep.welcome

    // MARK: - Init

    init(migrationEmailService: MigrationEmailService? = try? .init(),
         userPersistentRepository: UserPersistentRepository = UserPersistentStoreFactory.instance()) {
        self.migrationEmailService = migrationEmailService
        self.userPersistentRepository = userPersistentRepository
        self.userPersistentRepository.jetpackContentMigrationState = .inProgress

        // Skip the migration if the user just created an account and haven't
        // created any site yet.
        if BlogListDataSource().visibleBlogsCount == 0 {
            self.currentStep = MigrationStep.done
            self.userPersistentRepository.jetpackContentMigrationState = .completed
        }
    }

    deinit {
        if userPersistentRepository.jetpackContentMigrationState != .completed {
            self.userPersistentRepository.jetpackContentMigrationState = .notStarted
        }
    }

    // MARK: - Transitioning Steps

    func transitionToNextStep() {
        Task { [weak self] in
            guard let self = self, let nextStep = await Self.nextStep(from: currentStep) else {
                return
            }
            self.currentStep = nextStep
            self.didTransitionToStep(nextStep)
        }
    }

    private func didTransitionToStep(_ step: MigrationStep) {
        switch step {
        case .done:
            self.userPersistentRepository.jetpackContentMigrationState = .completed
            self.sendMigrationEmail()
        default:
            break
        }
    }

    // MARK: - Helpers

    private func sendMigrationEmail() {
        Task { [weak self] in
            try? await self?.migrationEmailService?.sendMigrationEmail()
        }
    }

    private static func shouldSkipNotificationsScreen() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let authStatus = settings.authorizationStatus
        return authStatus == .authorized || authStatus == .denied
    }

    private static func nextStep(from step: MigrationStep) async -> MigrationStep? {
        switch step {
        case .welcome:
            let shouldSkipNotifications = await shouldSkipNotificationsScreen()
            return shouldSkipNotifications ? .done : .notifications
        case .notifications:
            return .done
        case .done:
            return .dismiss
        case .dismiss:
            return nil
        }
    }
}

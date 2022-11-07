import Combine
import UserNotifications

/// Coordinator for the migration to jetpack flow
final class MigrationFlowCoordinator: ObservableObject {

    @Published private(set) var currentStep = MigrationStep.welcome

    func transitionToNextStep() {
        Task { [weak self] in
            if let nextStep = await Self.nextStep(from: currentStep) {
                self?.currentStep = nextStep
            }
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

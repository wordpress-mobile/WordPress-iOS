import Combine

/// Coordinator for the migration to jetpack flow
final class MigrationFlowCoordinator: ObservableObject {

    @Published private(set) var currentStep = MigrationStep.welcome

    func transitionToNextStep() {
        if let nextStep = Self.nextStep(from: currentStep) {
            self.currentStep = nextStep
        }
    }

    private static func nextStep(from step: MigrationStep) -> MigrationStep? {
        switch step {
        case .welcome:
            return .notifications
        case .notifications:
            return .done
        case .done:
            return .dismiss
        case .dismiss:
            return nil
        }
    }
}

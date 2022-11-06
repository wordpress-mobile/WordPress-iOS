import Foundation

class MigrationNotificationsViewModel {

    let configuration: MigrationStepConfiguration

    init(coordinator: MigrationFlowCoordinator) {
        self.configuration = MigrationStepConfiguration(headerConfiguration: MigrationHeaderConfiguration(step: .notifications),
                                                        actionsConfiguration: MigrationActionsViewConfiguration(step: .notifications,
                                                                                                                primaryHandler: {},
                                                                                                                secondaryHandler: { [weak coordinator] in
            coordinator?.transitionToNextStep()
        }))
    }
}

import Foundation

class MigrationNotificationsViewModel {

    let configuration: MigrationStepConfiguration

    init(coordinator: MigrationFlowCoordinator) {

        let headerConfiguration = MigrationHeaderConfiguration(step: .notifications)

        let centerViewConfigurartion = MigrationCenterViewConfiguration(step: .notifications)

        let actionsConfiguration = MigrationActionsViewConfiguration(step: .notifications,
                                                                     primaryHandler: {
            InteractiveNotificationsManager.shared.requestAuthorization { [weak coordinator] authorized in
                coordinator?.transitionToNextStep()
            }
        },
                                                                     secondaryHandler: { [weak coordinator] in
            coordinator?.transitionToNextStep()
        })

        configuration = MigrationStepConfiguration(headerConfiguration: headerConfiguration,
                                                   centerViewConfiguration: centerViewConfigurartion,
                                                   actionsConfiguration: actionsConfiguration)
    }
}

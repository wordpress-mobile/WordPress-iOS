class MigrationDoneViewModel {

    let configuration: MigrationStepConfiguration

    init(coordinator: MigrationFlowCoordinator) {

        let headerConfiguration = MigrationHeaderConfiguration(step: .done)

        let actionsConfiguration = MigrationActionsViewConfiguration(step: .done, primaryHandler: { [weak coordinator] in
                                                                                                        coordinator?.transitionToNextStep()
                                                                                                  })
        configuration = MigrationStepConfiguration(headerConfiguration: headerConfiguration,
                                                   actionsConfiguration: actionsConfiguration)
    }
}

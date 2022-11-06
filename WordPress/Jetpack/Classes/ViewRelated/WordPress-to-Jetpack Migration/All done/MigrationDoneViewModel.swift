class MigrationDoneViewModel {

    let configuration: MigrationStepConfiguration

    init(coordinator: MigrationFlowCoordinator) {

        configuration = MigrationStepConfiguration(headerConfiguration: MigrationHeaderConfiguration(step: .done),
                                                   actionsConfiguration: MigrationActionsViewConfiguration(step: .done, primaryHandler: { [weak coordinator] in
            coordinator?.transitionToNextStep()
        }))
    }
}

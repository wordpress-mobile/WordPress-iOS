class MigrationDoneViewModel {

    let configuration: MigrationStepConfiguration

    init(coordinator: MigrationFlowCoordinator, tracker: MigrationAnalyticsTracker = .init()) {

        let headerConfiguration = MigrationHeaderConfiguration(step: .done)

        let centerViewConfigurartion = MigrationCenterViewConfiguration(step: .done)

        let actionsConfiguration = MigrationActionsViewConfiguration(step: .done, primaryHandler: { [weak coordinator] in
            tracker.track(.thanksScreenFinishTapped)
            coordinator?.transitionToNextStep()
        })
        configuration = MigrationStepConfiguration(headerConfiguration: headerConfiguration,
                                                   centerViewConfiguration: centerViewConfigurartion,
                                                   actionsConfiguration: actionsConfiguration)
    }
}

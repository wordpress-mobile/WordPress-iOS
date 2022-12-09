import Foundation

class MigrationNotificationsViewModel {

    let configuration: MigrationStepConfiguration

    init(coordinator: MigrationFlowCoordinator, tracker: MigrationAnalyticsTracker = .init()) {
        let headerConfiguration = MigrationHeaderConfiguration(step: .notifications)
        let centerViewConfigurartion = MigrationCenterViewConfiguration(step: .notifications)

        let primaryHandler = { [weak coordinator] in
            tracker.track(.notificationsScreenContinueTapped)
            InteractiveNotificationsManager.shared.requestAuthorization { [weak coordinator] authorized in
                coordinator?.transitionToNextStep()
                let event: MigrationEvent = authorized ? .notificationsScreenPermissionGranted : .notificationsScreenPermissionDenied
                tracker.track(event)

                if authorized {
                    JetpackNotificationMigrationService.shared.rescheduleLocalNotifications()
                }
            }
        }
        let secondaryHandler = { [weak coordinator] in
            tracker.track(.notificationsScreenDecideLaterButtonTapped)
            coordinator?.transitionToNextStep()
        }
        let actionsConfiguration = MigrationActionsViewConfiguration(step: .notifications,
                                                                     primaryHandler: primaryHandler,
                                                                     secondaryHandler: secondaryHandler)

        configuration = MigrationStepConfiguration(headerConfiguration: headerConfiguration,
                                                   centerViewConfiguration: centerViewConfigurartion,
                                                   actionsConfiguration: actionsConfiguration)
    }
}

class MigrationDependencyContainer {

    let migrationCoordinator = MigrationFlowCoordinator()

    func makeInitialViewController() -> UIViewController {
        MigrationNavigationController(coordinator: migrationCoordinator,
                                      migrationStack: [.welcome: makeWelcomeViewController(),
                                                       .notifications: makeNotificationsViewController(),
                                                       .done: makeDoneViewController()])
    }

    private func makeAccount() -> WPAccount? {

        let context = ContextManager.shared.mainContext
        do {
            return try WPAccount.lookupDefaultWordPressComAccount(in: context)
        } catch {
            DDLogError("Account lookup failed with error: \(error)")
            return nil
        }
    }

    // MARK: view controller factory
    private func makeWelcomeViewModel() -> MigrationWelcomeViewModel {
        MigrationWelcomeViewModel(account: makeAccount(), coordinator: migrationCoordinator)
    }

    private func makeWelcomeViewController() -> UIViewController {
        MigrationWelcomeViewController(viewModel: makeWelcomeViewModel())
    }

    private func makeNotificationsViewModel() -> MigrationNotificationsViewModel {
        MigrationNotificationsViewModel(coordinator: migrationCoordinator)
    }

    private func makeNotificationsViewController() -> UIViewController {
        MigrationNotificationsViewController(viewModel: makeNotificationsViewModel())
    }

    private func makeDoneViewModel() -> MigrationDoneViewModel {
        MigrationDoneViewModel(coordinator: migrationCoordinator)
    }

    private func makeDoneViewController() -> UIViewController {
        MigrationDoneViewController(viewModel: makeDoneViewModel())
    }
}

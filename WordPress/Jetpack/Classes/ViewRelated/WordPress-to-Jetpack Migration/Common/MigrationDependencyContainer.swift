struct MigrationDependencyContainer {

    let migrationCoordinator = MigrationFlowCoordinator()

    func makeInitialViewController() -> UIViewController {
        MigrationNavigationController(coordinator: migrationCoordinator,
                                      factory: MigrationViewControllerFactory(coordinator: migrationCoordinator))
    }
}

struct MigrationViewControllerFactory {

    let coordinator: MigrationFlowCoordinator

    init(coordinator: MigrationFlowCoordinator) {
        self.coordinator = coordinator
    }

    func viewController(for step: MigrationStep) -> UIViewController? {
        switch step {
        case .welcome:
            return makeWelcomeViewController()
        case .notifications:
            return makeNotificationsViewController()
        case .done:
            return makeDoneViewController()
        case .dismiss:
            return nil
        }
    }

    func initialViewController() -> UIViewController? {
        viewController(for: coordinator.currentStep)
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

    private func makeWelcomeViewModel() -> MigrationWelcomeViewModel {
        MigrationWelcomeViewModel(account: makeAccount(), coordinator: coordinator)
    }

    private func makeWelcomeViewController() -> UIViewController {
        MigrationWelcomeViewController(viewModel: makeWelcomeViewModel())
    }

    private func makeNotificationsViewModel() -> MigrationNotificationsViewModel {
        MigrationNotificationsViewModel(coordinator: coordinator)
    }

    private func makeNotificationsViewController() -> UIViewController {
        MigrationNotificationsViewController(viewModel: makeNotificationsViewModel())
    }

    private func makeDoneViewModel() -> MigrationDoneViewModel {
        MigrationDoneViewModel(coordinator: coordinator)
    }

    private func makeDoneViewController() -> UIViewController {
        MigrationDoneViewController(viewModel: makeDoneViewModel())
    }
}

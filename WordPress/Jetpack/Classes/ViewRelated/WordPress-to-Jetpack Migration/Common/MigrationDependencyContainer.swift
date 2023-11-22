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

    // MARK: - View Controllers

    private func makeWelcomeViewModel(handlers: ActionHandlers) -> MigrationWelcomeViewModel {
        let primaryHandler = { () -> Void in handlers.primary?() }
        let secondaryHandler = { () -> Void in handlers.secondary?() }

        let actions = MigrationActionsViewConfiguration(
            step: .welcome,
            primaryHandler: primaryHandler,
            secondaryHandler: secondaryHandler
        )

        return .init(account: makeAccount(), actions: actions)
    }

    private func makeWelcomeViewController() -> UIViewController {
        let handlers = ActionHandlers()
        let viewModel = makeWelcomeViewModel(handlers: handlers)

        let viewController = MigrationWelcomeViewController(viewModel: viewModel)
        handlers.primary = { [weak coordinator] in coordinator?.transitionToNextStep() }
        handlers.secondary = makeSupportViewControllerRouter(with: viewController)

        return viewController
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

    // MARK: - Routers

    private func makeSupportViewControllerRouter(with presenter: UIViewController) -> () -> Void {
        return { [weak presenter] in
            let destination = SupportTableViewController(configuration: .currentAccountConfiguration(), style: .insetGrouped)
            presenter?.present(UINavigationController(rootViewController: destination), animated: true)
        }
    }

    // MARK: - Types

    private class ActionHandlers {
        var primary: (() -> Void)?
        var secondary: (() -> Void)?
    }
}

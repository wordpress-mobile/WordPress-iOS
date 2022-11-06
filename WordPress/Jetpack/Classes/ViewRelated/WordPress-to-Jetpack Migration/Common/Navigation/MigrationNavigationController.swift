import Combine
import UIKit

class MigrationNavigationController: UINavigationController {

    private let coordinator: MigrationFlowCoordinator
    /// The full navigation stack: keys are the states in which the corresponding view
    /// controller should be the root
    private let migrationStack: [MigrationStep: UIViewController]
    /// Receives state changes to set the navigation stack accordingly
    private var cancellable: AnyCancellable?

    init(coordinator: MigrationFlowCoordinator, migrationStack: [MigrationStep: UIViewController]) {
        self.coordinator = coordinator
        self.migrationStack = migrationStack
        super.init(nibName: nil, bundle: nil)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        let navigationBar = self.navigationBar
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()
        navigationBar.standardAppearance = standardAppearance
        navigationBar.scrollEdgeAppearance = scrollEdgeAppearance
        navigationBar.compactAppearance = standardAppearance
        if #available(iOS 15.0, *) {
            navigationBar.compactScrollEdgeAppearance = scrollEdgeAppearance
        }
        navigationBar.isTranslucent = true
        listenForStateChanges()
    }

    private func listenForStateChanges() {
        cancellable = coordinator.$currentStep.sink { [weak self] step in
            self?.updateStack(for: step)
        }
    }

    private func updateStack(for step: MigrationStep) {
        // sets the stack for the next navigation step, if there's one
        guard let viewController = migrationStack[step] else {
            return
        }
        // if we want to support backwards navigation, we need to set
        // also the previous steps in the stack
        setViewControllers([viewController], animated: true)
    }
}

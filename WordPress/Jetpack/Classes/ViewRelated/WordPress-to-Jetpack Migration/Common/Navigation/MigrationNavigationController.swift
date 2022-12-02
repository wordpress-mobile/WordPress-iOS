import Combine
import UIKit

class MigrationNavigationController: UINavigationController {
    /// Navigation coordinator
    private let coordinator: MigrationFlowCoordinator
    /// The view controller factory used to push view controllers on the stack
    private let factory: MigrationViewControllerFactory
    /// Receives state changes to set the navigation stack accordingly
    private var cancellable: AnyCancellable?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let presentedViewController {
            return presentedViewController.supportedInterfaceOrientations
        }
        if WPDeviceIdentification.isiPhone() {
            return .portrait
        } else {
            return .allButUpsideDown
        }
    }

    // Force portrait orientation for migration view controllers only
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        if let presentedViewController {
            return presentedViewController.preferredInterfaceOrientationForPresentation
        }
        return .portrait
    }

    init(coordinator: MigrationFlowCoordinator, factory: MigrationViewControllerFactory) {
        self.coordinator = coordinator
        self.factory = factory
        if let initialViewController = factory.initialViewController() {
            super.init(rootViewController: initialViewController)
        } else {
            super.init(nibName: nil, bundle: nil)
        }
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
        cancellable = coordinator.$currentStep
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] step in
                self?.updateStack(for: step)
            }
    }

    private func updateStack(for step: MigrationStep) {
        // sets the stack for the next navigation step, if there's one
        guard let viewController = factory.viewController(for: step) else {
            return
        }
        // if we want to support backwards navigation, we need to set
        // also the previous steps in the stack
        setViewControllers([viewController], animated: true)
    }
}

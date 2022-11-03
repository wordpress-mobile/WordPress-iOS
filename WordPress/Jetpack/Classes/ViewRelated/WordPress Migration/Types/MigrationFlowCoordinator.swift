import UIKit

final class MigrationFlowCoordinator {

    // MARK: - Properties

    private let account: WPAccount

    private(set) lazy var navigationController: UINavigationController = {
        let rootViewController = self.viewController(for: currentStep)
        let navigationController = UINavigationController(rootViewController: rootViewController)
        self.configure(navigationController: navigationController)
        return navigationController
    }()

    // MARK: - State

    private var currentStep = MigrationStep.welcome {
        didSet {
            self.didUpdateCurrentStep(currentStep)
        }
    }

    // MARK: - Init

    init(account: WPAccount) {
        self.account = account
    }

    // MARK: - Step Updates

    private func didUpdateCurrentStep(_ newValue: MigrationStep) {
        let viewController = self.viewController(for: newValue)
        self.navigationController.setViewControllers([viewController], animated: true)
    }

    // MARK: - User Interaction

    private func didTapContinue(in step: MigrationStep) {
        if let nextStep = Self.nextStep(from: step) {
            self.currentStep = nextStep
        } else {
            // Migration Flow is done
        }
    }

    // MARK: - View Controllers

    private func viewController(for step: MigrationStep) -> UIViewController {
        switch step {
        case .welcome:
            let viewModel = MigrationWelcomeViewModel(account: account, primaryAction: { self.didTapContinue(in: step) })
            return MigrationWelcomeViewController(viewModel: viewModel)
        default:
            // This is temporary
            let viewController = UIViewController()
            viewController.view.backgroundColor = .systemBackground
            return viewController
        }
    }

    private func configure(navigationController: UINavigationController) {
        let navigationBar = navigationController.navigationBar
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
    }

    // MARK: - Factories

    private static func nextStep(from step: MigrationStep) -> MigrationStep? {
        switch step {
        case .welcome: return .notification
        case .notification: return nil
        }
    }
}

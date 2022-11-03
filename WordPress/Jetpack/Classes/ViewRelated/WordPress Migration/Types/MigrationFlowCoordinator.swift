import UIKit

final class MigrationFlowCoordinator {

    // MARK: - Properties

    private let account: WPAccount

    private(set) lazy var navigationController: UINavigationController = {
        let rootViewController = self.viewController(for: currentStep)
        return MigrationFlowNavigationController(rootViewController: rootViewController)
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

    // MARK: - Factories

    private static func nextStep(from step: MigrationStep) -> MigrationStep? {
        switch step {
        case .welcome: return .notification
        case .notification: return nil
        }
    }
}

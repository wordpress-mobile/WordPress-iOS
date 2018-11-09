import UIKit

final class WizardNavigation {
    private let navigationController: UINavigationController

    lazy var content: UIViewController = {
        return self.navigationController
    }()

    init(root: UIViewController) {
        navigationController = UINavigationController(rootViewController: root)
    }

    func push(_ viewController: UIViewController) {
        navigationController.pushViewController(viewController, animated: true)
    }
}

import UIKit

class Restorer: NSObject {
    enum Identifier: String {
        case navigationController = "UINavigationController"

        func instantiate() -> UIViewController {
            let controller: UIViewController
            switch self {
            case .navigationController:
                controller = UINavigationController()
            }
            controller.restorationIdentifier = self.rawValue
            return controller
        }
    }

    @objc func viewController(identifier: String) -> UIViewController? {
        return Identifier(rawValue: identifier)?.instantiate()
    }
}

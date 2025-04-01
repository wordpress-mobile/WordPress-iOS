import UIKit

protocol ModalViewControllerPresenting {
    func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)?)
}

extension UIViewController: ModalViewControllerPresenting {}

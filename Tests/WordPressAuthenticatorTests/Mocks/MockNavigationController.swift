import UIKit

final class MockNavigationController: UINavigationController {
    var pushedViewController: UIViewController?

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
       pushedViewController = viewController
       super.pushViewController(viewController, animated: true)
     }
}

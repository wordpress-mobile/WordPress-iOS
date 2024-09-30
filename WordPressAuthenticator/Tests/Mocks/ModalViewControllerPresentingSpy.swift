@testable import WordPressAuthenticator

class ModalViewControllerPresentingSpy: UIViewController {
    internal var presentedVC: UIViewController? = .none
    override func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)?) {
        presentedVC = viewControllerToPresent
    }
}

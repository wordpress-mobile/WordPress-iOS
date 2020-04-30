
import UIKit


/// Concrete implementation of ScenePresenter that presents the Me scene
/// in a UISplitViewController/UINavigationController view hierarchy
@objc
class MeScenePresenter: NSObject, ScenePresenter {

    /// weak reference to the presented scene (no reference retained after it's dismissed)
    private(set) weak var presentedViewController: UIViewController?

    /// Done button action
    @objc
    private func dismissHandler() {
        self.presentedViewController?.dismiss(animated: true)
    }

    func present(on viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        // prevent presenting if the scene is already presented
        guard presentedViewController == nil else {
            completion?()
            return
        }
        let presentedViewController = makeNavigationController()
        self.presentedViewController = presentedViewController
        viewController.present(presentedViewController, animated: animated, completion: completion)
        WPAnalytics.track(.meTabAccessed)
    }
}


/// Presented UIViewController factory methods
private extension MeScenePresenter {

    func makeDoneButton() -> UIBarButtonItem {
        return UIBarButtonItem(target: self, action: #selector(dismissHandler))
    }

    func makeMeViewController() -> MeViewController {
        return MeViewController()
    }

    func makeNavigationController() -> UINavigationController {
        let meController = makeMeViewController()
        let navigationController = UINavigationController(rootViewController: meController)
        navigationController.restorationIdentifier = Restorer.Identifier.navigationController.rawValue
        meController.navigationItem.rightBarButtonItem = makeDoneButton()
        // present in formSheet on iPad, default on iPhone
        if WPDeviceIdentification.isiPad() {
            navigationController.modalPresentationStyle = .formSheet
            navigationController.modalTransitionStyle = .coverVertical
        }
        return navigationController
    }
}

/// Accessibility
extension UIBarButtonItem {
    /// Initialize a 'Done' UIBarButtonItem with the specified target/action
    /// - Parameters:
    ///   - target: target of the action to execute when the button is pressed
    ///   - action: selector of the action to execute when the button is pressed
    convenience init(target: Any?, action: Selector) {
        self.init(title: NSLocalizedString("Done", comment: "Title of the Done button on the me page"),
                  style: .done,
                  target: target,
                  action: action)
        makeDoneButtonAccessible()
    }

    /// Adds accessibility traits for the `Me` bar button item
    private func makeDoneButtonAccessible() {
        accessibilityLabel = NSLocalizedString("Done", comment: "Accessibility label for the Done button in the Me screen.")
        accessibilityHint = NSLocalizedString("Close the Me screen", comment: "Accessibility hint the  Done button in the Me screen.")
        accessibilityIdentifier = "doneBarButton"
        accessibilityTraits = UIAccessibilityTraits.button
        isAccessibilityElement = true
    }
}

import UIKit
import WordPressShared

public class LoginNavigationController: RotationAwareNavigationViewController {

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? WordPressAuthenticator.shared.style.statusBarStyle
    }

    public override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        // By default, the back button label uses the previous view's title.
        // To override that, reset the label when pushing a new view controller.
        self.viewControllers.last?.navigationItem.backButtonDisplayMode = .minimal

        super.pushViewController(viewController, animated: animated)
    }

}

// MARK: - RotationAwareNavigationViewController
//
public class RotationAwareNavigationViewController: UINavigationController {

    /// Should Autorotate: Respect the top child's orientation prefs.
    ///
    override open var shouldAutorotate: Bool {
        return topViewController?.shouldAutorotate ?? super.shouldAutorotate
    }

    /// Supported Orientations: Respect the top child's orientation prefs.
    ///
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let supportedOrientations = topViewController?.supportedInterfaceOrientations {
            return supportedOrientations
        }

        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        return isPad ? .all : .allButUpsideDown
    }
}

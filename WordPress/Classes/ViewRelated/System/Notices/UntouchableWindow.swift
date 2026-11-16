import UIKit

@objc class UntouchableWindow: UIWindow {
    let untouchableViewController = UntouchableViewController()

    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        rootViewController = untouchableViewController
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let view = rootViewController?.view as? UntouchableView else {
            return false
        }
        let relativePoint = convert(point, to: view)
        return view.point(inside: relativePoint, with: event)
    }
}

class UntouchableViewController: UIViewController {
    required init() {
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        super.loadView()
        view = UntouchableView()
    }

    var offsetOnscreen: CGFloat {
        // removed check for tabBarController.presentedViewController being nil here
        // when saving a draft in offline mode the editing view is dismissed
        // this causes the check for the presentedViewController to return nil
        // thus placing the notice incorrectly, without the proper space for the tabBar
        guard let tabBarController = visibleTabBarController else {
            return 0
        }

        return tabBarController.tabBar.frame.height
    }

    var offsetOffscreen: CGFloat {
        // we want 0 unless the tab bar has presented a VC
        guard let tabBarController = visibleTabBarController,
            tabBarController.presentedViewController != nil
        else {
            return 0
        }

        return Constants.offsetWithoutTabbar
    }

    /// The tab bar controller whose tab bar is at the bottom of the app window, if any.
    private var visibleTabBarController: WPTabBarController? {
        let rootViewController = UIApplication.shared.delegate?.window??.rootViewController
        if let tabBarController = rootViewController as? WPTabBarController {
            return tabBarController
        }
        // On iPad the root is a split view. It shows the tab bar only when the window is
        // narrow enough to collapse it.
        if let splitViewController = rootViewController as? UISplitViewController, splitViewController.isCollapsed {
            return splitViewController.viewController(for: .compact) as? WPTabBarController
        }
        return nil
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            guard let mainWindow = UIApplication.shared.delegate?.window,
                let rootController = mainWindow?.rootViewController
            else {
                return .all
            }

            return rootController.topmostPresentedViewController.supportedInterfaceOrientations
        }
    }

    enum Constants {
        static let offsetWithoutTabbar: CGFloat = 50.0
    }
}

private class UntouchableView: UIView {

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let visibleViews = subviews.filter { view -> Bool in
            view.alpha >= 0.01 && !view.isHidden && view.isUserInteractionEnabled
        }
        for view in visibleViews {
            let relativePoint = convert(point, to: view)
            if view.point(inside: relativePoint, with: event) {
                return true
            }
        }
        return false
    }
}

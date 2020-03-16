@objc class UntouchableWindow: UIWindow {
    let untouchableViewController  = UntouchableViewController()

    override init(frame: CGRect) {
        super.init(frame: frame)
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
        guard let mainWindow = UIApplication.shared.delegate?.window,
            let tabBarController = mainWindow?.rootViewController as? WPTabBarController else {
            return 0
        }

        return tabBarController.tabBar.frame.height
    }

    var offsetOffscreen: CGFloat {
        // we want 0 unless the tab bar has presented a VC
        guard let mainWindow = UIApplication.shared.delegate?.window,
            let tabBarController = mainWindow?.rootViewController as? WPTabBarController,
            tabBarController.presentedViewController != nil else {
                return 0
        }

        return Constants.offsetWithoutTabbar
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            guard let mainWindow = UIApplication.shared.delegate?.window,
                let rootController = mainWindow?.rootViewController else {
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
            return view.alpha >= 0.01 && !view.isHidden && view.isUserInteractionEnabled
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

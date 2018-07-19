import WordPressFlux

/// Allows the use of multiple UINavigationControllerDelegate by resending each message
private class NavigationControllerDelegateRepeater: NSObject, UINavigationControllerDelegate {
    private var delegates: NSHashTable<UINavigationControllerDelegate> = NSHashTable<UINavigationControllerDelegate>.weakObjects()

    func add(delegate: UINavigationControllerDelegate) {
        delegates.add(delegate)
    }

    // MARK: UINavigationControllerDelegate

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        for delegate in delegates.allObjects {
            delegate.navigationController?(navigationController, willShow: viewController, animated: animated)
        }
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        for delegate in delegates.allObjects {
            delegate.navigationController?(navigationController, didShow: viewController, animated: animated)
        }
    }

    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        for delegate in delegates.allObjects {
            if let transitioning = delegate.navigationController?(navigationController, animationControllerFor: operation, from: fromVC, to: toVC) {
                return transitioning
            }
        }
        return nil
    }
}

@objc
class ManyDelegateNavigationController: UINavigationController {
    private let delegateRepeater = NavigationControllerDelegateRepeater()

    override var delegate: UINavigationControllerDelegate? {
        set {
            guard let newDelegate = newValue else {
                return
            }

            delegateRepeater.add(delegate: newDelegate)
        }
        get {
            return delegateRepeater
        }
    }
}

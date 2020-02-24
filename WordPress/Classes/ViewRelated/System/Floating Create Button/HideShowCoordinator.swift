/// A class to hide/show a particular view based on view controller presentations
@objc class HideShowCoordinator: NSObject {

    private var tabBarObserver: NSKeyValueObservation?
    private var navigationDelegate: UINavigationControllerDelegate?

    /// Observes changes to the selected tab in order to show / hide `view` depending on the logic in `showFor`
    /// - Parameters:
    ///   - tabBarController: The Tab Bar Controller to observe
    ///   - showFor: A block to determine whether or not to show `view` upon a change to `viewController`
    ///   - view: The view to show and hide
    func observe(_ tabBarController: UITabBarController, showFor: @escaping (UIViewController) -> Bool, view: UIView) {
        let observation = tabBarController.observe(\.selectedViewController, options: []) { (tabBarController, change) in
            if let viewController = tabBarController.selectedViewController {
                let shouldShow = showFor(viewController)
                view.springAnimation(toShow: shouldShow)
            }
        }
        tabBarObserver = observation
    }

    /// Observes changes to the top view controller in the navigation stack in order to show / hide `view` depending on the logic in `showFor`
    /// - Parameters:
    ///   - tabBarController: The Tab Bar Controller to observe
    ///   - showFor: A block to determine whether or not to show `view` upon a change to `viewController`
    ///   - view: The view to show and hide
    func observe(_ navigationController: UINavigationController, showFor: @escaping (UIViewController) -> Bool, view: UIView) {
        let delegate = NavigationDelegate(didShow: { (navController, viewController, animated) in
            let shouldShow = showFor(viewController)
            if let transitionCoordinator = viewController.transitionCoordinator, transitionCoordinator.isInteractive {
                transitionCoordinator.animateAlongsideTransition(in: view, animation: { context in
                    view.springAnimation(toShow: shouldShow, context: context)
                }, completion: nil)
            } else {
                view.springAnimation(toShow: shouldShow)
            }
        })

        navigationController.delegate = delegate

        navigationDelegate = delegate
    }
}

private class NavigationDelegate: NSObject, UINavigationControllerDelegate {

    let didShow: (UINavigationController, UIViewController, Bool) -> Void

    init(didShow: @escaping (UINavigationController, UIViewController, Bool) -> Void) {
        self.didShow = didShow
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if viewController.transitionCoordinator?.initiallyInteractive == true {
            didShow(navigationController, viewController, animated)
        }
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController.transitionCoordinator?.initiallyInteractive == false {
            didShow(navigationController, viewController, animated)
        }
    }
}

// MARK: View Animations

extension UIView {

    /// Animates the showing and hiding of a view using a spring animation
    /// - Parameter toShow: Whether to show the view
    fileprivate func springAnimation(toShow: Bool, context: UIViewControllerTransitionCoordinatorContext? = nil) {
        if toShow {
            guard isHidden == true else { return }
            maximizeSpringAnimation(context: context)
        } else {
            guard isHidden == false else { return }
            minimizeSpringAnimation(context: context)
        }
    }

    /// Applies a spring animation, from size 1 to 0
    private func minimizeSpringAnimation(context: UIViewControllerTransitionCoordinatorContext?) {
        let damping: CGFloat = 0.9
        let scaleInitial: CGFloat = 1.0
        let scaleFinal: CGFloat = 0.001

        scaleAnimation(damping: damping, scaleInitial: scaleInitial, scaleFinal: scaleFinal, context: context) { [weak self] success in
            self?.transform = .identity
            self?.isHidden = true
        }
    }

    /// Applies a spring animation, from size 0 to 1
    private func maximizeSpringAnimation(context: UIViewControllerTransitionCoordinatorContext?) {
        let damping: CGFloat = 0.7
        let scaleInitial: CGFloat = 0.0
        let scaleFinal: CGFloat = 1.0

        scaleAnimation(damping: damping, scaleInitial: scaleInitial, scaleFinal: scaleFinal, context: context)
    }

    private func scaleAnimation(damping: CGFloat, scaleInitial: CGFloat, scaleFinal: CGFloat, context: UIViewControllerTransitionCoordinatorContext?, completion: ((Bool) -> Void)? = nil) {
        let duration = 0.5

        transform = CGAffineTransform(scaleX: scaleInitial, y: scaleInitial)
        isHidden = false

        let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: damping) {
            self.transform  = CGAffineTransform(scaleX: scaleFinal, y: scaleFinal)
        }

        animator.addCompletion { (position) in
            completion?(true)
        }

        animator.startAnimation()
    }
}

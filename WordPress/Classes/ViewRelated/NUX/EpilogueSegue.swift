import UIKit

protocol EpilogueAnimation {
}

/// Custom animation to allow presented views to appear to come from behind the presenter
extension EpilogueAnimation where Self: UIStoryboardSegue {
    func performEpilogue(completion: @escaping () -> Void) {
        guard let containerView = source.view.superview else {
            return
        }
        let sourceVC = source
        let destinationVC = destination
        let duration = 0.35

        var frame = sourceVC.view.frame
        // Adjust for the height of the status bar which seems to be ignored during the transition.
        frame.origin.y += 20
        frame.size.height -= 20
        destinationVC.view.frame = frame

        containerView.addSubview(destinationVC.view)
        containerView.addSubview(sourceVC.view)

        // Force hide the navigation bar and perform a layout pass so frames
        // are correct before starting the animation.
        sourceVC.navigationController?.setNavigationBarHidden(true, animated: false)
        sourceVC.navigationController?.view.layoutIfNeeded()

        UIView.animate(withDuration: duration, delay: 0, options:.curveEaseInOut, animations: {
            sourceVC.view.center.y += sourceVC.view.frame.size.height
        }) { (finished) in
            completion()
        }
    }
}

/// Presenting segue version of the EpilogueAnimation
class EpilogueSegue: UIStoryboardSegue, EpilogueAnimation {
    let duration = 0.35

    override func perform() {
        performEpilogue() {
            self.destination.view.removeFromSuperview()
            let navController = self.source.navigationController
            navController?.setViewControllers([self.destination], animated: false)
        }
    }
}

/// Unwinding segue version of the EpilogueAnimation
class EpilogueUnwindSegue: UIStoryboardSegue, EpilogueAnimation {
    let duration = 0.35

    override func perform() {
        performEpilogue() {}
    }
}

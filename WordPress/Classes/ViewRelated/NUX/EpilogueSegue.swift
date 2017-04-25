import UIKit

protocol EpilogueAnimation {
}

/// Custom animation to allow presented views to appear to come from behind the presenter
extension EpilogueAnimation where Self: UIStoryboardSegue {
    func performEpilogue(completion: @escaping (Void) -> ()) {
        guard let containerView = source.view.superview else {
            return
        }
        let sourceVC = source
        let destinationVC = destination
        let duration = 0.35

        destinationVC.view.frame = sourceVC.view.frame

        containerView.addSubview(destinationVC.view)
        containerView.addSubview(sourceVC.view)

        UIView.animate(withDuration: duration, delay: 0, options:UIViewAnimationOptions.curveEaseInOut, animations: {
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
            self.source.present(self.destination, animated: false) {}
        }
    }
}

/// Unwinding segue version of the EpilogueAnimation
class EpilogueUnwindSegue: UIStoryboardSegue, EpilogueAnimation {
    let duration = 0.35

    override func perform() {
        performEpilogue() {
            self.destination.dismiss(animated: false) {}
        }
    }
}

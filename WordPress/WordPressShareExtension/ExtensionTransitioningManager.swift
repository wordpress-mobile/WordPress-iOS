import UIKit

enum Direction {
    case left
    case top
    case right
    case bottom
}

final class ExtensionTransitioningManager: NSObject {
    var direction = Direction.bottom
}

// MARK: - UIViewControllerTransitioningDelegate

extension ExtensionTransitioningManager: UIViewControllerTransitioningDelegate {

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentationController = ExtensionPresentationController(presentedViewController: presented, presenting: presenting, direction: direction)
        presentationController.delegate = self
        return presentationController
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ExtensionPresentationAnimator(direction: direction, isPresentation: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ExtensionPresentationAnimator(direction: direction, isPresentation: false)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension ExtensionTransitioningManager: UIAdaptivePresentationControllerDelegate {

    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        if traitCollection.verticalSizeClass == .compact {
            return .overFullScreen
        } else {
            return .none
        }
    }
}

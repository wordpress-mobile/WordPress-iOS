//
//  EpilogueSegue.swift
//  WordPress
//
//  Created by Nate Heagy on 2017-04-12.
//  Copyright © 2017 WordPress. All rights reserved.
//

import UIKit

internal var _animator: EpilogueAnimator?

class EpilogueSegue: UIStoryboardSegue {
    override init(identifier: String?, source: UIViewController, destination: UIViewController) {
        super.init(identifier: identifier, source: source, destination: destination)
        
        _animator = EpilogueAnimator(presentedViewController: destination, presenting: source)
    }
    
    override func perform() {
        destination.transitioningDelegate = _animator
        source.present(destination, animated: true) {}
    }
}

class EpilogueAnimator: UIPresentationController {
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        
        presentedViewController.modalPresentationStyle = .custom
    }
}

extension EpilogueAnimator: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
}

extension EpilogueAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.35
    }
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
              let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
            return
        }
        containerView.addSubview(toVC.view)
        containerView.addSubview(fromVC.view)

        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, delay: 0, options:UIViewAnimationOptions.curveEaseIn, animations: {
            fromVC.view.center.y += fromVC.view.frame.size.height
        }) { (finished) in
            transitionContext.completeTransition(finished)
        }
    }
}

import UIKit

final class LoginEpilogueAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    private enum Constants {
        static let loginAnimationDuration = 0.3
        static let loginAnimationScaleX = 1.0
        static let loginAnimationScaleY = 1.2
        static let quickStartAnimationDuration = 0.3
        static let quickStartPromptStartAlpha = 0.2
        static let quickStartTopEndConstraint = 80.0
        static let hiddenAlpha = 0.0
        static let visibleAlpha = 1.0
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Constants.loginAnimationDuration + Constants.quickStartAnimationDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let loginEpilogueViewController = transitionContext.viewController(forKey: .from) as? LoginEpilogueViewController,
              let quickStartPromptViewController = transitionContext.viewController(forKey: .to) as? QuickStartPromptViewController,
              let selectedCell = loginEpilogueViewController.tableViewController?.selectedCell else {
                  return
              }

        let containerView = transitionContext.containerView
        containerView.backgroundColor = loginEpilogueViewController.view.backgroundColor

        let cellSnapshot = selectedCell.contentView.snapshotView(afterScreenUpdates: false)
        let cellSnapshotFrame = containerView.convert(selectedCell.contentView.frame, from: selectedCell)
        cellSnapshot?.frame = cellSnapshotFrame
        selectedCell.contentView.alpha = Constants.hiddenAlpha

        let loginContainer = UIView(frame: loginEpilogueViewController.view.frame)
        let loginSnapshot = loginEpilogueViewController.view.snapshotView(afterScreenUpdates: true)
        loginContainer.backgroundColor = loginEpilogueViewController.view.backgroundColor

        if let loginSnapshot = loginSnapshot {
            loginSnapshot.layer.anchorPoint = CGPoint(x: 0.5, y: cellSnapshotFrame.origin.y / loginContainer.bounds.height)
            loginSnapshot.frame = loginContainer.frame
            loginContainer.addSubview(loginSnapshot)
            containerView.addSubview(loginContainer)
        }

        if let cellSnapshot = cellSnapshot {
            containerView.addSubview(cellSnapshot)
        }

        quickStartPromptViewController.view.alpha = Constants.hiddenAlpha
        let safeAreaTop = loginEpilogueViewController.view.safeAreaInsets.top
        quickStartPromptViewController.scrollViewTopVerticalConstraint.constant = cellSnapshotFrame.origin.y - safeAreaTop
        quickStartPromptViewController.promptTitleLabel.alpha = Constants.quickStartPromptStartAlpha
        quickStartPromptViewController.promptDescriptionLabel.alpha = Constants.quickStartPromptStartAlpha
        quickStartPromptViewController.showMeAroundButton.alpha = Constants.hiddenAlpha
        quickStartPromptViewController.noThanksButton.alpha = Constants.hiddenAlpha
        quickStartPromptViewController.view.layoutIfNeeded()
        containerView.addSubview(quickStartPromptViewController.view)

        let quickStartAnimator = UIViewPropertyAnimator(duration: Constants.quickStartAnimationDuration, curve: .easeInOut) {
            quickStartPromptViewController.promptTitleLabel.alpha = Constants.visibleAlpha
            quickStartPromptViewController.promptDescriptionLabel.alpha = Constants.visibleAlpha
            quickStartPromptViewController.showMeAroundButton.alpha = Constants.visibleAlpha
            quickStartPromptViewController.noThanksButton.alpha = Constants.visibleAlpha
            quickStartPromptViewController.scrollViewTopVerticalConstraint.constant = Constants.quickStartTopEndConstraint
            quickStartPromptViewController.view.layoutIfNeeded()
        }

        quickStartAnimator.addCompletion { position in
            cellSnapshot?.alpha = Constants.hiddenAlpha
            selectedCell.contentView.alpha = Constants.visibleAlpha
            transitionContext.completeTransition(position == .end)
        }

        let loginAnimator = UIViewPropertyAnimator(duration: Constants.loginAnimationDuration, curve: .easeOut) {
            loginSnapshot?.alpha = Constants.hiddenAlpha
            loginSnapshot?.transform = CGAffineTransform(scaleX: Constants.loginAnimationScaleX, y: Constants.loginAnimationScaleY)
        }

        loginAnimator.addCompletion { _ in
            quickStartPromptViewController.view.alpha = Constants.visibleAlpha
            quickStartAnimator.startAnimation()
        }

        loginAnimator.startAnimation()
    }

}

import UIKit

public struct NoticeAnimator {

    enum Transition {
        case onscreen
        case offscreen
    }

    let duration: TimeInterval
    let springDampening: CGFloat
    let springVelocity: CGFloat

    typealias AnimationBlock = () -> Void

    func state(
        for noticeContainer: NoticeContainerView,
        in view: UIView? = nil,
        withTransition transition: Transition,
        bottomOffset: CGFloat = 0
    ) -> AnimationBlock {
        {
            let presentation = noticeContainer.noticeView

            let alpha: CGFloat
            switch transition {
            case .onscreen:
                alpha = 1
            case .offscreen:
                alpha = 0
            }

            noticeContainer.noticeView.alpha = alpha

            switch presentation.notice.style.animationStyle {
            case .moveIn:
                noticeContainer.bottomConstraint?.constant = bottomOffset
                noticeContainer.bottomConstraint?.isActive = transition == .onscreen
                noticeContainer.topConstraint?.isActive = transition == .offscreen
            case .fade:
                // Fade just changes the alpha value which both animations need
                break
            }

            view?.layoutIfNeeded()
        }
    }

    func animatePresentation(
        fromState: AnimationBlock,
        toState: @escaping AnimationBlock,
        completion: AnimationBlock?
    ) {
        fromState()

        // this delay avoids affecting other transitions like navigation pushes
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .nanoseconds(1)) {
            UIView.animate(
                withDuration: self.duration,
                delay: 0,
                usingSpringWithDamping: self.springDampening,
                initialSpringVelocity: self.springVelocity,
                options: [],
                animations: toState,
                completion: { _ in
                    completion?()
                }
            )
        }
    }
}

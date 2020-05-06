import Foundation

public struct NoticeAnimator {

    let duration: TimeInterval
    let springDampening: CGFloat
    let springVelocity: CGFloat

    /// Present the `Notice` inside of any view. If the notice includes a `sourceView` the constraints will be attached to that view (so the `sourceView` and `view` parameter **MUST** be in the same view hierarchy).
    /// - Parameters:
    ///   - notice: The `Notice` to present.
    ///   - view: The `UIView` to add the `Notice` to.
    /// - Returns: <#description#>
    func present(notice: Notice, in view: UIView, sourceView: UIView) -> NoticeContainerView {
        let noticeView = NoticeView(notice: notice)
        noticeView.configureArrow()
        noticeView.translatesAutoresizingMaskIntoConstraints = false

        let noticeContainerView = NoticeContainerView(noticeView: noticeView)
        view.addSubview(noticeContainerView)

        let bottomConstraint = noticeContainerView.bottomAnchor.constraint(equalTo: sourceView.topAnchor)
        let leadingConstraint = noticeContainerView.constrain(attribute: .leading, toView: view, relatedBy: .greaterThanOrEqual, constant: 0)
        let trailingConstraint = noticeContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        trailingConstraint.priority = .defaultHigh // During rotation this may need to break

        NSLayoutConstraint.activate([
            leadingConstraint,
            trailingConstraint,
            bottomConstraint
        ])

        animate(noticeContainer: noticeContainerView)

        return noticeContainerView
    }

    func animate(noticeContainer: NoticeContainerView, completion: (() -> Void)? = nil) {
        noticeContainer.noticeView.alpha = WPAlphaZero

        let fromState = offscreenState(for: noticeContainer)
        let toState = onscreenState(for: noticeContainer)
        animatePresentation(fromState: fromState, toState: toState, completion: completion)
    }

    func offscreenState(for noticeContainer: NoticeContainerView, in view: UIView? = nil, bottomOffset: CGFloat = 0) -> AnimationBlock {
        return {

            let presentation = noticeContainer.noticeView

            noticeContainer.noticeView.alpha = WPAlphaZero

            switch presentation.notice.style.animationStyle {
            case .moveIn:
                noticeContainer.bottomConstraint?.constant = bottomOffset
            case .fade:
                // Fade just changes the alpha value which both animations need
                break
            }

            view?.layoutIfNeeded()
        }
    }

    func onscreenState(for noticeContainer: NoticeContainerView, in view: UIView? = nil, bottomOffset: CGFloat = 0) -> AnimationBlock {
        return {

            let presentation = noticeContainer.noticeView

            noticeContainer.noticeView.alpha = WPAlphaFull

            switch presentation.notice.style.animationStyle {
            case .moveIn:
                noticeContainer.bottomConstraint?.constant = bottomOffset
            case .fade:
                // Fade just changes the alpha value which both animations need
                break
            }

            view?.layoutIfNeeded()
        }
    }

    typealias AnimationBlock = () -> Void

    func animatePresentation(fromState: AnimationBlock,
                                     toState: @escaping AnimationBlock,
                                     completion: AnimationBlock?) {
        fromState()

        // this delay avoids affecting other transitions like navigation pushes
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .nanoseconds(1)) {
            UIView.animate(withDuration: self.duration,
                           delay: 0,
                           usingSpringWithDamping: self.springDampening,
                           initialSpringVelocity: self.springVelocity,
                           options: [],
                           animations: toState,
                           completion: { _ in
                            completion?()
            })
        }
    }
}

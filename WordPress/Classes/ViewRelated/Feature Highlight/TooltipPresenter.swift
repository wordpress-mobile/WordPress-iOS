import UIKit

/// A helper class for presentation of the Tooltip in respect to a `targetView`.
/// Must be retained to respond to device orientation and size category changes.
final class TooltipPresenter {
    private enum Constants {
        static let verticalTooltipDistanceToFocus: CGFloat = 8
        static let horizontalBufferMargin: CGFloat = 20
        static let tooltipTopConstraintAnimationOffset: CGFloat = 8
        static let tooltipAnimationDuration: TimeInterval = 0.2
    }

    private let containerView: UIView
    private let tooltip: Tooltip
    private let targetView: UIView
    private var primaryTooltipAction: (() -> Void)?
    private var secondaryTooltipAction: (() -> Void)?

    private var tooltipTopConstraint: NSLayoutConstraint?

    init(containerView: UIView,
         tooltip: Tooltip,
         targetView: UIView,
         primaryTooltipAction: (() -> Void)? = nil,
         secondaryTooltipAction: (() -> Void)? = nil
    ) {
        self.containerView = containerView
        self.tooltip = tooltip
        self.targetView = targetView
        self.primaryTooltipAction = primaryTooltipAction
        self.secondaryTooltipAction = secondaryTooltipAction

        configureDismissal()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(resetTooltipAndShow),
            name: UIContentSizeCategory.didChangeNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(resetTooltipAndShow),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    func show() {
        containerView.addSubview(tooltip)
        self.tooltip.alpha = 0
        tooltip.addArrowHead(toXPosition: arrowOffsetX(), arrowPosition: tooltipOrientation())
        setUpConstraints()
        containerView.layoutIfNeeded()

        UIView.animate(
            withDuration: Constants.tooltipAnimationDuration,
            delay: 0,
            options: .curveEaseOut
        ) {
            guard let tooltipTopConstraint = self.tooltipTopConstraint else { return }

            self.tooltip.alpha = 1
            tooltipTopConstraint.constant -= Constants.tooltipTopConstraintAnimationOffset
            self.containerView.layoutIfNeeded()
        }
    }

    private func configureDismissal() {
        tooltip.dismissalAction = {
            UIView.animate(
                withDuration: Constants.tooltipAnimationDuration,
                delay: 0,
                options: .curveEaseOut
            ) {
                guard let tooltipTopConstraint = self.tooltipTopConstraint else { return }

                self.tooltip.alpha = 0
                tooltipTopConstraint.constant += Constants.tooltipTopConstraintAnimationOffset
                self.containerView.layoutIfNeeded()
            } completion: { isSuccess in
                self.primaryTooltipAction?()
                self.tooltip.removeFromSuperview()
            }
        }
    }

    private func setUpConstraints() {
        tooltip.translatesAutoresizingMaskIntoConstraints = false

        var tooltipConstraints: [NSLayoutConstraint] = [
            tooltip.centerXAnchor.constraint(equalTo: containerView.centerXAnchor, constant: extraArrowOffsetX())
        ]

        switch tooltipOrientation() {
        case .bottom:
            tooltipTopConstraint = targetView.topAnchor.constraint(
                equalTo: tooltip.bottomAnchor,
                constant: Constants.verticalTooltipDistanceToFocus + Constants.tooltipTopConstraintAnimationOffset
            )
        case .top:
            tooltipTopConstraint = tooltip.topAnchor.constraint(
                equalTo: targetView.bottomAnchor,
                constant: Constants.verticalTooltipDistanceToFocus + Constants.tooltipTopConstraintAnimationOffset
            )
        }

        tooltipConstraints.append(tooltipTopConstraint!)
        NSLayoutConstraint.activate(tooltipConstraints)
    }

    @objc private func resetTooltipAndShow() {
        tooltip.removeFromSuperview()
        show()
    }

    /// Calculates where the arrow needs to place in the borders of the tooltip.
    /// This depends on the position of the `targetView` relative to `tooltip`.
    private func arrowOffsetX() -> CGFloat {
        return targetView.frame.midX - ((containerView.bounds.width - tooltip.size().width) / 2) - extraArrowOffsetX()
    }

    /// If the tooltip is always vertically centered, tooltip's width may not be big enough to reach to the `targetView`
    /// If `xxxxxxxx` is the Tooltip and `oo` is the `targetView`:
    /// |                                               |
    /// |                xxxxxxxx                 |
    /// |                                    oo       |
    /// The tooltip needs an extra X offset to be aligned with target so that tooltip arrow points to the correct position.
    /// Here the tooltip is pushed to the right so the arrow is pointing at the `targetView`
    /// |                                               |
    /// |                           xxxxxxxx     |
    /// |                                    oo       |
    /// It would be retracted instead of the `targetView` was at the left of the screen.
    ///
    private func extraArrowOffsetX() -> CGFloat {
        let tooltipWidth = tooltip.size().width
        let extraPushOffset = max(
            (targetView.frame.midX + Constants.horizontalBufferMargin) - (containerView.frame.midX + tooltipWidth / 2),
            0
        )
        let extraRetractOffset = min(
            (targetView.frame.midX - Constants.horizontalBufferMargin) - (containerView.frame.midX - tooltipWidth / 2),
            0
        )

        if extraPushOffset > 0 {
            return extraPushOffset
        }

        return extraRetractOffset
    }


    private func tooltipOrientation() -> Tooltip.ArrowPosition {
        if containerView.frame.midY < targetView.frame.minY {
            return .bottom
        }
        return .top
    }
}

import UIKit

/// A helper class for presentation of the Tooltip in respect to a `targetView`.
/// Must be retained to respond to device orientation and size category changes.
final class TooltipPresenter {
    private enum Constants {
        static let verticalTooltipDistanceToFocus: CGFloat = 8
        static let horizontalBufferMargin: CGFloat = 20
    }

    private let containerView: UIView
    private let tooltip: Tooltip
    private let targetView: UIView

    init(containerView: UIView, tooltip: Tooltip, targetView: UIView) {
        self.containerView = containerView
        self.tooltip = tooltip
        self.targetView = targetView
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recalculatePosition),
            name: UIContentSizeCategory.didChangeNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recalculatePosition),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    func show() {
        containerView.addSubview(tooltip)
        tooltip.addArrowHead(toXPosition: arrowOffsetX(), arrowPosition: tooltipOrientation())
        setUpConstraints()
    }

    private func setUpConstraints() {
        tooltip.translatesAutoresizingMaskIntoConstraints = false

        var tooltipConstraints: [NSLayoutConstraint] = [
            tooltip.centerXAnchor.constraint(equalTo: containerView.centerXAnchor, constant: extraArrowOffsetX())
        ]

        switch tooltipOrientation() {
        case .bottom:
            tooltipConstraints.append(
                targetView.topAnchor.constraint(
                    equalTo: tooltip.bottomAnchor,
                    constant: Constants.verticalTooltipDistanceToFocus
                )
            )
        case .top:
            tooltipConstraints.append(
                tooltip.topAnchor.constraint(
                    equalTo: targetView.bottomAnchor,
                    constant: Constants.verticalTooltipDistanceToFocus
                )
            )
        }

        NSLayoutConstraint.activate(tooltipConstraints)
    }

    @objc private func recalculatePosition() {
        tooltip.removeFromSuperview()
        show()
    }

    /// Calculates where the arrow needs to place in the borders of the tooltia.
    /// This depends on the position of the `targetView` relative to `tooltip`.
    private func arrowOffsetX() -> CGFloat {
        return targetView.frame.midX - ((containerView.bounds.width - tooltip.size().width) / 2) - extraArrowOffsetX()
    }

    /// If the tooltip is alwyas vertically centered, tooltip's width may not be big enough to reach to the `targetView`
    /// If `xxxxxxxx` is the Tooltip and `oo` is the `targetView`:
    /// |                                               |
    /// |                xxxxxxxx                 |
    /// |                                    oo       |
    /// The tooltip needs an extra X offset to be aligned with target so that tooltip arrow points to the correct position.
    /// Here the tooltip is pushed to the right so the arrow
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

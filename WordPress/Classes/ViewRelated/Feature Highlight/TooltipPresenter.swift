import UIKit

/// A helper class for presentation of the Tooltip in respect to a `targetView`.
/// Must be retained to respond to device orientation and size category changes.
final class TooltipPresenter {
    private enum Constants {
        static let verticalTooltipDistanceToFocus: CGFloat = 8
        static let horizontalBufferMargin: CGFloat = 20
        static let tooltipTopConstraintAnimationOffset: CGFloat = 8
        static let tooltipAnimationDuration: TimeInterval = 0.2
        static let anchorBottomConstraintConstant: CGFloat = 58
    }

    enum TooltipVerticalPosition {
        case auto
        case above
        case below
    }

    enum Target {
        case view(UIView)
        case point(CGPoint)
    }

    private let containerView: UIView
    private let tooltip: Tooltip
    private var primaryTooltipAction: (() -> Void)?
    private var secondaryTooltipAction: (() -> Void)?
    private var anchor: TooltipAnchor?
    private var tooltipTopConstraint: NSLayoutConstraint?
    private var anchorAction: (() -> Void)?
    private let target: Target

    private var targetMidX: CGFloat {
        switch target {
        case .view(let targetView):
            return targetView.frame.midX
        case .point(let targetPoint):
            return targetPoint.x
        }
    }

    private var targetMinY: CGFloat {
        switch target {
        case .view(let targetView):
            return targetView.frame.minY
        case .point(let targetPoint):
            return targetPoint.y
        }
    }


    var tooltipVerticalPosition: TooltipVerticalPosition = .auto

    init(containerView: UIView,
         tooltip: Tooltip,
         target: Target,
         primaryTooltipAction: (() -> Void)? = nil,
         secondaryTooltipAction: (() -> Void)? = nil
    ) {
        self.containerView = containerView
        self.tooltip = tooltip
        self.primaryTooltipAction = primaryTooltipAction
        self.secondaryTooltipAction = secondaryTooltipAction
        self.target = target

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

    func attachAnchor(withTitle title: String, onView view: UIView, anchorAction: @escaping (() -> Void)) {
        let anchor = TooltipAnchor()
        self.anchor = anchor
        self.anchorAction = anchorAction
        anchor.title = title
        anchor.addTarget(self, action: #selector(didTapAnchor), for: .touchUpInside)
        anchor.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(anchor)

        NSLayoutConstraint.activate([
            anchor.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(
                equalTo: anchor.bottomAnchor,
                constant: Constants.anchorBottomConstraintConstant
            )
        ])
    }

    func toggleAnchorVisibility(_ isVisible: Bool) {
        guard let anchor = anchor else {
            return
        }

        anchor.isHidden = !isVisible
    }

    func showTooltip() {
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

    @objc private func didTapAnchor() {
        anchorAction?()
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

        switch target {
        case .view(let targetView):
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
        case .point(let targetPoint):
            switch tooltipOrientation() {
            case .bottom:
                tooltipTopConstraint = tooltip.bottomAnchor.constraint(
                    equalTo: containerView.topAnchor,
                    constant: targetPoint.y + Constants.verticalTooltipDistanceToFocus + Constants.tooltipTopConstraintAnimationOffset
                )
            case .top:
                tooltipTopConstraint = tooltip.bottomAnchor.constraint(
                    equalTo: containerView.topAnchor,
                    constant: targetPoint.y
                    + Constants.verticalTooltipDistanceToFocus
                    + Constants.tooltipTopConstraintAnimationOffset
                    + tooltip.size().height
                )
            }
        }

        tooltipConstraints.append(tooltipTopConstraint!)
        NSLayoutConstraint.activate(tooltipConstraints)
    }

    @objc private func resetTooltipAndShow() {
        tooltip.removeFromSuperview()
        showTooltip()
    }

    /// Calculates where the arrow needs to place in the borders of the tooltip.
    /// This depends on the position of the target relative to `tooltip`.
    private func arrowOffsetX() -> CGFloat {
        return targetMidX - ((containerView.bounds.width - tooltip.size().width) / 2) - extraArrowOffsetX()
    }

    /// If the tooltip is always vertically centered, tooltip's width may not be big enough to reach to the target
    /// If `xxxxxxxx` is the Tooltip and `oo` is the target:
    /// |                                               |
    /// |                xxxxxxxx                 |
    /// |                                    oo       |
    /// The tooltip needs an extra X offset to be aligned with target so that tooltip arrow points to the correct position.
    /// Here the tooltip is pushed to the right so the arrow is pointing at the target
    /// |                                               |
    /// |                           xxxxxxxx     |
    /// |                                    oo       |
    /// It would be retracted instead if the target was at the left of the screen.
    ///
    private func extraArrowOffsetX() -> CGFloat {
        let tooltipWidth = tooltip.size().width
        let extraPushOffset = max(
            (targetMidX + Constants.horizontalBufferMargin) - (containerView.frame.midX + tooltipWidth / 2),
            0
        )
        let extraRetractOffset = min(
            (targetMidX - Constants.horizontalBufferMargin) - (containerView.frame.midX - tooltipWidth / 2),
            0
        )

        if extraPushOffset > 0 {
            return extraPushOffset
        }

        return extraRetractOffset
    }


    private func tooltipOrientation() -> Tooltip.ArrowPosition {
        switch tooltipVerticalPosition {
        case .auto:
            if containerView.frame.midY < targetMinY {
                return .bottom
            }
            return .top
        case .above:
            return .bottom
        case .below:
            return .top
        }
    }
}

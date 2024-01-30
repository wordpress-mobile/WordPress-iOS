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
        static let spotlightViewBufferHeight: CGFloat = 38
        static let spotlightViewRadius: CGFloat = 20
    }

    enum TooltipVerticalPosition {
        case auto
        case above
        case below
    }

    enum Target {
        case view(UIView)
        case point((() -> CGPoint))
    }

    private let containerView: UIView
    private var spotlightView: QuickStartSpotlightView?
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
            return targetPoint().x
        }
    }

    private var targetMinY: CGFloat {
        switch target {
        case .view(let targetView):
            return targetView.frame.minY
        case .point(let targetPoint):
            return targetPoint().y
        }
    }

    private(set) var tooltip: Tooltip
    var tooltipVerticalPosition: TooltipVerticalPosition = .auto
    private let shouldShowSpotlightView: Bool

    private var totalVerticalBuffer: CGFloat {
        Constants.verticalTooltipDistanceToFocus
        + Constants.tooltipTopConstraintAnimationOffset
    }

    private var spotlightVerticalBuffer: CGFloat {
        switch target {
        case .view:
            return totalVerticalBuffer
        case .point:
            return totalVerticalBuffer + Constants.spotlightViewBufferHeight
        }
    }

    private var previousDeviceOrientation: UIDeviceOrientation?

    init(containerView: UIView,
         tooltip: Tooltip,
         target: Target,
         shouldShowSpotlightView: Bool,
         primaryTooltipAction: (() -> Void)? = nil,
         secondaryTooltipAction: (() -> Void)? = nil
    ) {
        self.containerView = containerView
        self.tooltip = tooltip
        self.shouldShowSpotlightView = shouldShowSpotlightView
        self.primaryTooltipAction = primaryTooltipAction
        self.secondaryTooltipAction = secondaryTooltipAction
        self.target = target

        configureDismissal()

        previousDeviceOrientation = UIDevice.current.orientation
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(resetTooltipAndShow),
            name: UIContentSizeCategory.didChangeNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didDeviceOrientationChange),
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
        anchor.alpha = 0
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

        anchor.toggleVisibility(isVisible)
    }

    func showTooltip() {
        containerView.addSubview(tooltip)
        self.tooltip.alpha = 0
        tooltip.addArrowHead(toXPosition: arrowOffsetX(), arrowPosition: tooltipOrientation())
        setUpTooltipConstraints()

        containerView.layoutIfNeeded()
        animateTooltipIn()
    }

    func dismissTooltip() {
        UIView.animate(
            withDuration: Constants.tooltipAnimationDuration,
            delay: 0,
            options: .curveEaseOut
        ) {
            guard let tooltipTopConstraint = self.tooltipTopConstraint else {
                return
            }

            self.tooltip.alpha = 0
            tooltipTopConstraint.constant += Constants.tooltipTopConstraintAnimationOffset
            self.containerView.layoutIfNeeded()
        } completion: { isSuccess in
            self.anchor = nil
            self.primaryTooltipAction?()
            self.tooltip.removeFromSuperview()
            self.spotlightView?.removeFromSuperview()
            NotificationCenter.default.removeObserver(self)
        }
    }

    private func animateTooltipIn() {
        UIView.animate(
            withDuration: Constants.tooltipAnimationDuration,
            delay: 0,
            options: .curveEaseOut
        ) {
            guard let tooltipTopConstraint = self.tooltipTopConstraint else {
                return
            }

            self.tooltip.alpha = 1
            tooltipTopConstraint.constant -= Constants.tooltipTopConstraintAnimationOffset

            self.containerView.layoutIfNeeded()
        } completion: { success in
            if self.shouldShowSpotlightView {
                self.showSpotlightView()
            }
        }
    }

    @objc private func didTapAnchor() {
        anchorAction?()
    }

    private func configureDismissal() {
        tooltip.dismissalAction = dismissTooltip
    }

    private func setUpTooltipConstraints() {
        tooltip.translatesAutoresizingMaskIntoConstraints = false

        var tooltipConstraints = [
            tooltip.centerXAnchor.constraint(equalTo: containerView.centerXAnchor, constant: extraArrowOffsetX())
        ]

        let verticalExtraSpotlightOffset: CGFloat = 14

        switch target {
        case .view(let targetView):
            switch tooltipOrientation() {
            case .bottom:
                tooltipTopConstraint = targetView.topAnchor.constraint(
                    equalTo: tooltip.bottomAnchor,
                    constant: spotlightVerticalBuffer + verticalExtraSpotlightOffset
                )
            case .top:
                tooltipTopConstraint = tooltip.topAnchor.constraint(
                    equalTo: targetView.bottomAnchor,
                    constant: spotlightVerticalBuffer + verticalExtraSpotlightOffset
                )
            }
        case .point(let targetPoint):
            switch tooltipOrientation() {
            case .bottom:
                tooltipTopConstraint = tooltip.bottomAnchor.constraint(
                    equalTo: containerView.topAnchor,
                    constant: targetPoint().y + totalVerticalBuffer
                )
            case .top:
                tooltipTopConstraint = tooltip.topAnchor.constraint(
                    equalTo: containerView.topAnchor,
                    constant: targetPoint().y
                    + spotlightVerticalBuffer + verticalExtraSpotlightOffset
                )
            }
        }

        tooltipConstraints.append(tooltipTopConstraint!)
        NSLayoutConstraint.activate(tooltipConstraints)
    }

    private func showSpotlightView() {
        spotlightView?.removeFromSuperview()
        spotlightView = QuickStartSpotlightView()
        guard let spotlightView = spotlightView else {
            return
        }

        spotlightView.translatesAutoresizingMaskIntoConstraints = false
        spotlightView.isUserInteractionEnabled = false
        containerView.addSubview(spotlightView)

        if let constraints = spotlightViewConstraints() {
            NSLayoutConstraint.activate(constraints)
        }
    }

    private func spotlightViewConstraints() -> [NSLayoutConstraint]? {
        guard let spotlightView = spotlightView else {
            return nil
        }

        // `leftAnchor` is used because the `arrowOffsetX` is calculated as an absolute point.
        // So it is required to constraint always to left (or right) to support LTR and RTL languages.
        var constraints = [
            spotlightView.leftAnchor.constraint(
                equalTo: containerView.leftAnchor,
                constant: arrowOffsetX() + tooltip.frame.minX - Constants.spotlightViewRadius
            )
        ]

        let verticalConstraint: NSLayoutConstraint

        switch target {
        case .view(let targetView):
            verticalConstraint = spotlightVerticalConstraint(spotlightView, targetView: targetView)
        case .point(let targetPoint):
            verticalConstraint = spotlightVerticalConstraint(spotlightView, targetPoint: targetPoint)
        }

        constraints.append(verticalConstraint)

        return constraints
    }

    private func spotlightVerticalConstraint(
        _ spotlightView: QuickStartSpotlightView,
        targetView: UIView) -> NSLayoutConstraint {
            switch tooltipOrientation() {
            case .bottom:
                return targetView.topAnchor.constraint(
                    equalTo: spotlightView.topAnchor,
                    constant: spotlightVerticalBuffer
                )
            case .top:
                return targetView.bottomAnchor.constraint(
                    equalTo: spotlightView.topAnchor,
                    constant: Constants.spotlightViewRadius
                )
            }
        }

    private func spotlightVerticalConstraint(
        _ spotlightView: QuickStartSpotlightView,
        targetPoint: (() -> CGPoint)) -> NSLayoutConstraint {
            switch tooltipOrientation() {
            case .bottom:
                return spotlightView.bottomAnchor.constraint(
                    equalTo: containerView.topAnchor,
                    constant: targetPoint().y
                    + spotlightVerticalBuffer
                )
            case .top:
                return spotlightView.topAnchor.constraint(
                    equalTo: containerView.topAnchor,
                    constant: targetPoint().y
                    + totalVerticalBuffer
                )
            }
        }

    /// `orientationDidChangeNotification` is published when the device is at `faceUp` or `faceDown`
    ///  states too. The sizing won't be affected in these cases so no need to reset the tooltip. Here we filter out changes
    ///  to and from `faceUp` & `faceDown`.
    @objc private func didDeviceOrientationChange() {
        guard let previousDeviceOrientation = previousDeviceOrientation else {
            return
        }

        self.previousDeviceOrientation = UIDevice.current.orientation

        switch (previousDeviceOrientation, UIDevice.current.orientation) {
        case (_, .faceUp), (_, .faceDown), (.faceUp, _), (.faceDown, _):
            return
        default:
            resetTooltipAndShow()
        }
    }

    @objc private func resetTooltipAndShow() {
        UIView.animate(
            withDuration: Constants.tooltipAnimationDuration,
            delay: 0,
            options: .curveEaseOut
        ) {
            guard let tooltipTopConstraint = self.tooltipTopConstraint else {
                return
            }

            self.tooltip.alpha = 0
            tooltipTopConstraint.constant += Constants.tooltipTopConstraintAnimationOffset
            self.containerView.layoutIfNeeded()
        } completion: { isSuccess in
            self.tooltip.removeFromSuperview()
            self.tooltip = self.tooltip.copy()
            self.showTooltip()
        }
    }

    /// Calculates where the arrow needs to place in the borders of the tooltip.
    /// This depends on the position of the target relative to `tooltip`.
    private func arrowOffsetX() -> CGFloat {
        targetMidX - ((containerView.bounds.width - tooltip.size().width) / 2) - extraArrowOffsetX()
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
            (targetMidX + Constants.horizontalBufferMargin) - (containerView.safeAreaLayoutGuide.layoutFrame.midX + tooltipWidth / 2),
            0
        )

        if extraPushOffset > 0 {
            return extraPushOffset
        }

        let extraRetractOffset = min(
            (targetMidX - Constants.horizontalBufferMargin) - (containerView.safeAreaLayoutGuide.layoutFrame.midX - tooltipWidth / 2),
            0
        )

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

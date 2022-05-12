import UIKit

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
    }

    func show() {
        containerView.addSubview(tooltip)
        tooltip.addArrowHead(toXPosition: arrowOffsetX(), arrowPosition: tooltipOrientation())
        setUpConstraints()
    }

    private func setUpConstraints() {
        tooltip.translatesAutoresizingMaskIntoConstraints = false

        var tooltipConstriants: [NSLayoutConstraint] = [
            tooltip.centerXAnchor.constraint(equalTo: containerView.centerXAnchor, constant: extraArrowOffsetX())
        ]

        switch tooltipOrientation() {
        case .bottom:
            tooltipConstriants.append(
                targetView.topAnchor.constraint(
                    equalTo: tooltip.bottomAnchor,
                    constant: Constants.verticalTooltipDistanceToFocus
                )
            )
        case .top:
            tooltipConstriants.append(
                tooltip.topAnchor.constraint(
                    equalTo: targetView.bottomAnchor,
                    constant: Constants.verticalTooltipDistanceToFocus
                )
            )
        }

        NSLayoutConstraint.activate(tooltipConstriants)
    }

    private func arrowOffsetX() -> CGFloat {
        return targetView.frame.midX - ((containerView.bounds.width - tooltip.size().width) / 2) - extraArrowOffsetX()
    }

    private func extraArrowOffsetX() -> CGFloat {
        let tooltipWidth = tooltip.size().width
        let extraPushOffset = max((targetView.frame.midX + Constants.horizontalBufferMargin) - (containerView.frame.midX + tooltipWidth / 2), 0)
        let extraRetractOffset = min((targetView.frame.midX - Constants.horizontalBufferMargin) - (containerView.frame.midX - tooltipWidth / 2), 0)

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

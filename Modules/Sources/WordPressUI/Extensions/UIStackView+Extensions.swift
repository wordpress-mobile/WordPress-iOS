import UIKit

extension UIStackView {
    public convenience init(
        axis: NSLayoutConstraint.Axis = .horizontal,
        alignment: UIStackView.Alignment = .fill,
        distribution: UIStackView.Distribution = .fill,
        spacing: CGFloat? = nil,
        insets: UIEdgeInsets? = nil,
        _ arrangedSubviews: [UIView]
    ) {
        self.init(arrangedSubviews: arrangedSubviews)
        self.axis = axis
        self.alignment = alignment
        self.distribution = distribution
        if let spacing {
            self.spacing = spacing
        }
        if let insets {
            self.isLayoutMarginsRelativeArrangement = true
            self.layoutMargins = insets
        }
    }
}

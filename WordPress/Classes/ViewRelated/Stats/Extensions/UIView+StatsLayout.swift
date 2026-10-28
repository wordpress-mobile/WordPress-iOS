import UIKit

extension UILabel {
    /// Creates a label for a Stats view, with the defaults the Stats xibs used.
    static func makeStatsLabel(
        text: String? = nil,
        textStyle: UIFont.TextStyle,
        textColor: UIColor? = nil,
        textAlignment: NSTextAlignment = .natural,
        numberOfLines: Int = 1
    ) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.contentMode = .left
        label.isOpaque = false
        label.backgroundColor = nil
        label.textAlignment = textAlignment
        label.text = text
        label.font = .preferredFont(forTextStyle: textStyle)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = numberOfLines
        if let textColor {
            label.textColor = textColor
        }
        label.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        label.setContentHuggingPriority(UILayoutPriority(251), for: .vertical)
        return label
    }
}

extension UIView {
    /// Creates a hairline separator for a Stats view. Its colour is set by `WPStyleGuide.Stats`.
    static func makeStatsSeparator(height: CGFloat = 0.5) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }
}

extension UIView {
    /// Gives a view built in code the size and resizing behaviour its xib's root view had.
    ///
    /// A view loaded from a xib starts at the root view's design size, with its autoresizing
    /// mask, so callers could add it with `addSubview` and no constraints. Keep that working.
    func applyStatsXibRootDefaults(size: CGSize, mask: AutoresizingMask = [.flexibleWidth, .flexibleHeight]) {
        if frame.size == .zero {
            frame.size = size
        }
        autoresizingMask = mask
    }
}

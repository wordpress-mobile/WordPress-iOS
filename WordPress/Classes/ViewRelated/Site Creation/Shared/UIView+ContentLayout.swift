import UIKit
import WordPressShared

// MARK: - UILabel

extension UILabel {

    /// Convenience method that sets text & accessibility label.
    ///
    /// - Parameter value: the text to affix to the label
    func setText(_ value: String) {
        self.text = value
        accessibilityLabel = value
    }
}

// MARK: - UIView

extension UIView {

    /// Oftentimes, the readable content guide is used to layout content.
    /// For Site Creation, however, compact-width content is "full bleed."
    /// This computed property implements this fallback logic.
    ///
    /// The result follows the window's horizontal size class (Site Creation is a page sheet, which
    /// reports a compact size class in a wide iPad window), so constraints anchored to it must be
    /// rebuilt when the window's size class changes.
    var prevailingLayoutGuide: UILayoutGuide {
        let layoutGuide: UILayoutGuide
        if (window ?? self).traitCollection.horizontalSizeClass == .regular {
            layoutGuide = readableContentGuide
        } else {
            layoutGuide = safeAreaLayoutGuide
        }

        return layoutGuide
    }

    /// Convenience method to add multiple `UIView` instances as subviews en masse.
    ///
    /// - Parameter views: the views to install as subviews
    func addSubviews(_ views: [UIView]) {
        views.forEach(addSubview)
    }
}

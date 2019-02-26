
import UIKit

// MARK: - Subview convenience methods for `UIStackView`

extension UIStackView {
    /// Convenience method to add multiple `UIView` instances as arranged subviews en masse.
    ///
    /// - Parameter views: the views to install as arranged subviews
    ///
    func addArrangedSubviews(_ views: [UIView]) {
        views.forEach(addArrangedSubview)
    }

    /// Convenience method to remove all subviews from a stack view.
    ///
    func removeAllSubviews() {
        for view in self.subviews {
            removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
}

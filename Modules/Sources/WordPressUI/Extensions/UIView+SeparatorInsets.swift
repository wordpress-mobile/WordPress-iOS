import UIKit

extension UIView {
    /// Returns a `separatorInset` for a table view or cell that is measured from the edges of the
    /// view's safe area instead of the view's own edges.
    ///
    /// Setting an explicit `separatorInset` replaces the inset UIKit picks by default, which keeps
    /// the separator out of the side safe areas. Without this, the separator runs under the iPhone
    /// Duo's side strip, or under the sensor housing in landscape.
    ///
    /// A separator inset follows the layout direction (its `left` is the leading side), but safe
    /// area insets don't, so they are swapped in right-to-left layouts.
    public func separatorInsets(leading: CGFloat, trailing: CGFloat = 0) -> UIEdgeInsets {
        let isRightToLeft = effectiveUserInterfaceLayoutDirection == .rightToLeft
        let leadingSafeArea = isRightToLeft ? safeAreaInsets.right : safeAreaInsets.left
        let trailingSafeArea = isRightToLeft ? safeAreaInsets.left : safeAreaInsets.right
        return UIEdgeInsets(top: 0, left: leading + leadingSafeArea, bottom: 0, right: trailing + trailingSafeArea)
    }
}

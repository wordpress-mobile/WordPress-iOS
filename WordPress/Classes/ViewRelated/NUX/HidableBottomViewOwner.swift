import UIKit

/// Any UIViewControllers who has a bottom view that should have a hiding
/// ability can conform to this protocol so showing/hiding is already handled.
protocol HidableBottomViewOwner {

    /// Distance constraint between the hidable view's bottom and the conforming view's bottom
    var bottomViewBottomConstraint: NSLayoutConstraint! { get }

    /// Height constraint of the hidable view
    var bottomViewHeightConstraint: NSLayoutConstraint! { get }
}

extension HidableBottomViewOwner where Self: UIViewController {

    /// Shows/hides bottom view
    ///
    /// - Parameters:
    ///   - show: true shows, false hides
    ///   - animation: showing/hiding is done animatedly if true
    func showButtonView(show: Bool, withAnimation animation: Bool) {

        let duration = animation ? WPAnimationDurationDefault : 0

        UIView.animate(withDuration: duration, animations: {
            if show {
                self.bottomViewBottomConstraint.constant = 0
            }
            else {
                // Move the view down double the height to ensure it's off the screen.
                // i.e. to defy iPhone X bottom gap.
                self.bottomViewBottomConstraint.constant +=
                    self.bottomViewHeightConstraint.constant * 2
            }

            // Since the Button View uses auto layout, need to call this so the animation works properly.
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}

import UIKit

protocol HidableBottomViewOwner {
    var bottomViewBottomConstraint: NSLayoutConstraint! { get }
    var bottomViewHeightConstraint: NSLayoutConstraint! { get }
}

extension HidableBottomViewOwner where Self: UIViewController {

    func showButtonView(show: Bool, withAnimation: Bool) {

        let duration = withAnimation ? WPAnimationDurationDefault : 0

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

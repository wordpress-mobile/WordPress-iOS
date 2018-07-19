import UIKit

/// UIViewController subclasses who has a bottom view that should have a hiding
/// ability can conform to this protocol so showing/hiding is already handled.
protocol DomainSuggestionsButtonViewToggle {

    /// Distance constraint between the hidable view's bottom and the conforming view's bottom
    var buttonContainerViewBottomConstraint: NSLayoutConstraint! { get }

    /// Height constraint of the hidable view
    var buttonContainerViewHeightConstraint: NSLayoutConstraint! { get }
}

extension DomainSuggestionsButtonViewToggle where Self: UIViewController {

    /// Shows/hides bottom view
    ///
    /// - Parameters:
    ///   - show: true shows, false hides
    ///   - animation: showing/hiding is done animatedly if true
    func showButtonView(show: Bool, withAnimation animation: Bool) {

        let duration = animation ? WPAnimationDurationDefault : 0

        UIView.animate(withDuration: duration, animations: {
            if show {
                self.buttonContainerViewBottomConstraint.constant = 0
            }
            else {
                // Move the view down double the height to ensure it's off the screen.
                // i.e. to defy iPhone X bottom gap.
                self.buttonContainerViewBottomConstraint.constant +=
                    self.buttonContainerViewHeightConstraint.constant * 2
            }

            // Since the Button View uses auto layout, need to call this so the animation works properly.
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}

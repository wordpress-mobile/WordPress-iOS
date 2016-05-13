import UIKit
import MRProgress

class PurchaseButton: RoundedButton {
    var animatesWhenSelected: Bool = true

    private var collapseConstraint: NSLayoutConstraint!
    private lazy var activityIndicatorView: MRActivityIndicatorView = {
        let activityView = MRActivityIndicatorView(frame: self.bounds)
        activityView.tintColor = self.tintColor
        activityView.lineWidth = 1.0

        self.addSubview(activityView)
        activityView.translatesAutoresizingMaskIntoConstraints = false

        self.pinSubviewAtCenter(activityView)
        activityView.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor).active = true
        activityView.widthAnchor.constraintEqualToAnchor(self.widthAnchor).active = true
        activityView.widthAnchor.constraintEqualToAnchor(activityView.heightAnchor).active = true

        return activityView
    }()

    override func awakeFromNib() {
        super.awakeFromNib()

        collapseConstraint = widthAnchor.constraintEqualToAnchor(heightAnchor)
    }

    private var _cornerRadius: CGFloat = 0
    override var selected: Bool {
        didSet {
            if oldValue == selected { return }

            if selected {
                collapseConstraint.active = true

                UIView.animateWithDuration(0.3, animations: {
                    // Save the corner radius so we can restore it later
                    self._cornerRadius = self.cornerRadius
                    self.cornerRadius = self.bounds.height / 2
                    self.titleLabel?.alpha = 0

                    // Ask the superview to layout if necessary, because the
                    // button has changed size. This is required otherwise
                    // we were seeing an animation glitch where the superview's
                    // constraints weren't animating correctly to contain the
                    // button as it changed size.
                    // See https://github.com/wordpress-mobile/WordPress-iOS/pull/5361
                    // for more info.
                    self.superview?.layoutIfNeeded()
                    }, completion:  { finished in
                        self.activityIndicatorView.startAnimating()
                        self.borderWidth = 0
                })
            } else {
                collapseConstraint.active = false

                self.activityIndicatorView.stopAnimating()

                UIView.animateWithDuration(0.3, animations: {
                    self.cornerRadius = self._cornerRadius
                    self.borderWidth = 1

                    // See comment above
                    self.superview?.layoutIfNeeded()
                    }, completion:  { finished in
                        self.titleLabel?.alpha = 1
                })
            }
        }
    }
}

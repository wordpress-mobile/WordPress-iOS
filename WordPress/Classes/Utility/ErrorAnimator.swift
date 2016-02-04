import UIKit
import WordPressShared

/// ErrorAnimator is a helper class to animate error messages.
///
/// The error messages show at the top of the target view, and are meant to
/// appear to be attached to a navigation bar. The expected usage is to display
/// offline status or requests taking longer than usual.
///
/// To use an ErrorAnimator, you need to keep a reference to it, and call two
/// methods:
///
///  - `layout()` from your `UIView.layoutSubviews()` or
/// `UIViewController.viewDidLayoutSubviews()`. Failure to do this won't render
/// the animation correctly.
///
///  - `animateErrorMessage(_)` when you want to change the error displayed. Pass
/// nil if you want to hide the error view.
///
class ErrorAnimator: Animator {
    let animationDuration = 0.3
    let targetHeight: CGFloat = 40

    private var errorLabel: PaddedLabel? = nil
    private var message: String? = nil
    private var showingError: Bool {
        return (message != nil)
    }
    let targetView: UIView
    var targetTableView: UITableView? {
        return targetView as? UITableView
    }

    init(target: UIView) {
        targetView = target
        super.init()
    }

    func layout() {
        if let errorLabel = errorLabel {
            let errorFrame = errorLabel.frame
            var frame = targetView.bounds
            frame.size.height = errorFrame.height
            errorLabel.frame = frame
        }
    }

    func animateErrorMessage(message: String?) {
        let previouslyShowing = showingError
        // Are we showing or hiding the message
        self.message = message

        if previouslyShowing != showingError {
            animateWithDuration(animationDuration, preamble: preamble, animations: animations, cleanup: cleanup)
        }
        if showingError {
            errorLabel?.label.text = message
        }
    }

    private func preamble() {
        if showingError {
            errorLabel = createErrorLabel()
            targetView.addSubview(errorLabel!)
            errorLabel?.frame.size.height = 0
            errorLabel?.label.alpha = 0
        }

        UIView.performWithoutAnimation { [unowned self] in
            self.targetView.layoutIfNeeded()
        }
    }

    private func animations() {
        if showingError {
            errorLabel?.frame.size.height = targetHeight
            errorLabel?.label.alpha = 1

            targetTableView?.contentInset.top += targetHeight
            if targetTableView?.contentOffset.y == 0 {
                targetTableView?.contentOffset.y = -targetHeight
            }
        } else {
            errorLabel?.frame.size.height = 0
            errorLabel?.label.alpha = 0

            targetTableView?.contentInset.top -= targetHeight
        }
        targetView.layoutIfNeeded()
    }

    private func cleanup() {
        if !showingError {
            errorLabel?.removeFromSuperview()
            errorLabel = nil
        }
    }

    private func createErrorLabel() -> PaddedLabel {
        let paddedLabel = PaddedLabel()
        paddedLabel.padding.horizontal = 15
        paddedLabel.label.textColor = UIColor.whiteColor()
        paddedLabel.backgroundColor = WPStyleGuide.mediumBlue()
        paddedLabel.label.font = WPStyleGuide.regularTextFont()
        return paddedLabel
    }
}

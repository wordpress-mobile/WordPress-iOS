import UIKit

/// Animator is a helper to build responsive animations.
///
/// The main benefit of this class are the preamble and cleanup blocks, which
/// are only called before/after all the animations.
///
/// You should keep a reference to the animator object, and use the same
/// animator for related animations.
///
/// A very simple example of preamble and cleanup:
///
///     class MyViewController: UIViewController {
///         lazy var animator = Animator()
///         var showError: Bool = false {
///             didSet {
///                 animator.animateWithDuration(0.3,
///                     preamble: { [unowned self] in
///                         if self.showError {
///                             let view = self.createErrorView()
///                             self.view.addSubview(view)
///                             self.errorView = view
///                             self.errorView?.alpha = 0
///                         }
///                     }, animations: { [unowned self] in
///                         self.errorView?.alpha = 1
///                     }, cleanup: { [unowned self] in
///                         if !self.showError {
///                             self.errorView?.removeFromSuperview()
///                             self.errorView = nil
///                         }
///                     })
///             }
///         }
///
///         func createErrorView() -> UIView {
///             // Create the error view
///         }
///         var errorView: UIView? = nil
///     }
///
/// Animator is heavily inspired by the final demo on WWDC 2014 Session 236
/// [Building Interruptible and Responsive Interactions](https://developer.apple.com/videos/play/wwdc2014-236/).
class Animator: NSObject {
    fileprivate var animationsInProgress = 0

    /// Animates changes to one or more views using the specified duration.
    ///
    /// - Parameters:
    ///     - preamble: A block called before the animations start. It will only be called if there were no previous animations.
    ///     - animations: A block object containing the changes to commit to the views.
    ///     - cleanup: A block called after the animations complete if there are no more pending animations.
    ///
    @objc func animateWithDuration(_ duration: TimeInterval, preamble: (() -> Void)? = nil, animations: @escaping () -> Void, cleanup: (() -> Void)? = nil) {
        precondition(Thread.isMainThread, "Animator only works on the main (UI) thread")

        if animationsInProgress == 0 {
            preamble?()
        }

        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: animations) { [unowned self] _ in
            self.animationsInProgress -= 1

            if self.animationsInProgress == 0 {
                cleanup?()
            }
        }

        animationsInProgress += 1
    }
}

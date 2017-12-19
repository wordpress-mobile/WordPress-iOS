import Foundation
import WordPressShared


/// This UINavigationController subclass will take care, automatically, of hiding the UINavigationBar
/// whenever:
///
/// -   We're running on an iPad Device
/// -   The presentation style is not set to fullscreen (AKA "we're in Popover Mode!")
///
/// Note that we won't hide the NavigationBar on iPhone devices, since the *Plus* devices, in landscape mode,
/// do render the presentedView within a popover, but you cannot actually dismiss it, by tapping over the
/// gray area.
///
class AdaptiveNavigationController: UINavigationController {

    /// Insets to be applied on the SourceView's Coordinates, in order to fine tune the Popover's arrow position.
    ///
    private let sourceInsets = CGVector(dx: -10, dy: 0)


    /// This is the main method of this helper: we'll set both, the Presentation Style, Presentation Delegate,
    /// and SourceView parameters, accordingly.
    ///
    ///  - Parameter presentingView: UIView instance from which the popover will be shown
    ///
    @objc func configurePopoverPresentationStyle(from sourceView: UIView) {
        modalPresentationStyle = .popover

        guard let presentationController = popoverPresentationController else {
            fatalError()
        }

        presentationController.sourceRect = sourceView.bounds.insetBy(dx: sourceInsets.dx, dy: sourceInsets.dy)
        presentationController.sourceView = sourceView
        presentationController.permittedArrowDirections = .any
        presentationController.delegate = self
    }
}


// MARK: - UIPopoverPresentationControllerDelegate Methods
//
extension AdaptiveNavigationController: UIPopoverPresentationControllerDelegate {
    func presentationController(_ presentationController: UIPresentationController, willPresentWithAdaptiveStyle style: UIModalPresentationStyle, transitionCoordinator: UIViewControllerTransitionCoordinator?) {
        guard let navigationController = presentationController.presentedViewController as? UINavigationController else {
            return
        }

        let hidesNavigationBar = style != .fullScreen && WPDeviceIdentification.isiPad()
        navigationController.navigationBar.isHidden = hidesNavigationBar
    }
}

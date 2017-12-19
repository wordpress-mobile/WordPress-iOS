import UIKit

/// This delegate forces popover presentation even on iPhone / in compact size classes
class ForcePopoverPresenter: NSObject, UIPopoverPresentationControllerDelegate {
    @objc static let presenter = ForcePopoverPresenter()

    fileprivate static let verticalPadding: CGFloat = 10

    /// Configures a view controller to use a popover presentation style
    @objc static func configurePresentationControllerForViewController(_ controller: UIViewController, presentingFromView sourceView: UIView) {
        controller.modalPresentationStyle = .popover

        let presentationController = controller.popoverPresentationController
        presentationController?.permittedArrowDirections = .any
        presentationController?.sourceView = sourceView

        // Outset the source rect vertically to push the popover up / down a little
        // when displayed. Otherwise, when presented from a navigation controller
        // the top of the popover lines up perfectly with the bottom of the
        // navigation controller and looks a little odd
        presentationController?.sourceRect = sourceView.bounds.insetBy(dx: 0, dy: -verticalPadding)
        presentationController?.delegate = ForcePopoverPresenter.presenter

        controller.view.sizeToFit()
    }

    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

import SwiftUI
import UIKit

/// Presents the share sheet for `payload`. On iPad the sheet is a popover that
/// points at this view's frame, so place the presenter where the popover should
/// point (e.g. in the Share button's background).
///
/// The sheet is presented through UIKit instead of SwiftUI's `.sheet(item:)`:
/// a SwiftUI sheet can't tell `UIActivityViewController` which control started
/// the share, so its iPad popover had to be anchored on its own view, which put
/// it in the window's corner or center.
///
/// When `payload` becomes nil while the sheet is up, the sheet is dismissed
/// without calling `onDismiss`.
struct ShareSheetPresenter: UIViewControllerRepresentable {
    typealias Payload = MediaDetailViewModel.SharePayload

    let payload: Payload?
    var permittedArrowDirections: UIPopoverArrowDirection = .any
    /// Called once the sheet for a payload has appeared.
    var onPresent: () -> Void = {}
    /// Called when the user dismisses the sheet, with whether they completed
    /// an activity.
    let onDismiss: (_ payload: Payload, _ completed: Bool) -> Void

    func makeUIViewController(context: Context) -> AnchorViewController {
        AnchorViewController()
    }

    func updateUIViewController(_ controller: AnchorViewController, context: Context) {
        controller.request = payload.map {
            AnchorViewController.Request(
                payload: $0,
                permittedArrowDirections: permittedArrowDirections,
                onPresent: onPresent,
                onDismiss: onDismiss
            )
        }
    }

    final class AnchorViewController: UIViewController {
        struct Request {
            let payload: Payload
            let permittedArrowDirections: UIPopoverArrowDirection
            let onPresent: () -> Void
            let onDismiss: (_ payload: Payload, _ completed: Bool) -> Void
        }

        var request: Request? {
            didSet {
                if request == nil {
                    dismissSheet()
                } else {
                    // Present on the next run loop turn, outside SwiftUI's
                    // view update.
                    DispatchQueue.main.async { [weak self] in self?.presentIfNeeded() }
                }
            }
        }

        private weak var activityController: UIActivityViewController?
        private var presentedPayloadID: UUID?

        override func loadView() {
            let anchorView = AnchorView()
            anchorView.isUserInteractionEnabled = false
            anchorView.onMoveToWindow = { [weak self] in
                // A payload that arrives while the screen is off-window (e.g.
                // the download finished while another tab was selected) waits
                // until the screen is back instead of presenting over that tab.
                DispatchQueue.main.async { self?.presentIfNeeded() }
            }
            view = anchorView
        }

        private func presentIfNeeded() {
            guard let request,
                request.payload.id != presentedPayloadID,
                view.window != nil,
                presentedViewController == nil
            else {
                return
            }
            presentedPayloadID = request.payload.id

            let controller = UIActivityViewController(activityItems: request.payload.urls, applicationActivities: nil)
            controller.completionWithItemsHandler = { _, completed, _, _ in
                request.onDismiss(request.payload, completed)
            }
            // iPhone presents a sheet and ignores these.
            if let popover = controller.popoverPresentationController {
                popover.sourceView = view
                popover.sourceRect = view.bounds
                popover.permittedArrowDirections = request.permittedArrowDirections
            }
            activityController = controller
            present(controller, animated: true, completion: request.onPresent)
        }

        private func dismissSheet() {
            // Only dismiss our own sheet. `dismiss(animated:)` on a view
            // controller that presents nothing is forwarded up the hierarchy,
            // and could dismiss the screen that hosts this view.
            guard let activityController,
                presentedViewController === activityController,
                !activityController.isBeingDismissed
            else {
                return
            }
            dismiss(animated: true)
        }
    }

    private final class AnchorView: UIView {
        var onMoveToWindow: (() -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil {
                onMoveToWindow?()
            }
        }
    }
}

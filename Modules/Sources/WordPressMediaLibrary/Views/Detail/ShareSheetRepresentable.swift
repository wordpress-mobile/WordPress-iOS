import SwiftUI
import UIKit

struct ShareSheetRepresentable: UIViewControllerRepresentable {
    let urls: [URL]
    let onDismiss: (_ completed: Bool) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            onDismiss(completed)
        }
        // On iPad, `UIActivityViewController` defaults to popover
        // presentation and crashes if no anchor is set. SwiftUI's
        // `.sheet(item:)` doesn't expose the originating Share toolbar
        // button as a popover source, so anchor on the activity
        // controller's own view (centered, no arrow) — a centered modal
        // popover. iPhone presentations ignore the popover settings.
        if let popover = controller.popoverPresentationController {
            popover.sourceView = controller.view
            popover.sourceRect = CGRect(
                x: controller.view.bounds.midX,
                y: controller.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

import SwiftUI
import UIKit

struct ReaderSubscriptionNotificationSettingsView: UIViewControllerRepresentable {
    let siteID: Int
    var isCompact = false

    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = NotificationSiteSubscriptionViewController(siteId: siteID)
        if isCompact {
            vc.navigationItem.rightBarButtonItem = UIBarButtonItem(title: SharedStrings.Button.done, primaryAction: .init { _ in
                dismiss()
            })
            // - warning: UIKit is used to prevent the modifiers from the
            // containing list to affect this screen/
            return UINavigationController(rootViewController: vc)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Do nothing
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiViewController: UIViewController, context: Context) -> CGSize? {
        isCompact ? nil : CGSize(width: 320, height: 434)
    }
}

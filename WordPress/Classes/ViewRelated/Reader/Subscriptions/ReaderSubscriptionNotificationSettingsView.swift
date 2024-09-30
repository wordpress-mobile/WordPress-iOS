import SwiftUI
import UIKit

struct ReaderSubscriptionNotificationSettingsView: UIViewControllerRepresentable {
    let siteID: Int

    func makeUIViewController(context: Context) -> NotificationSiteSubscriptionViewController {
        NotificationSiteSubscriptionViewController(siteId: siteID)
    }

    func updateUIViewController(_ uiViewController: NotificationSiteSubscriptionViewController, context: Context) {
        // Do nothing
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiViewController: NotificationSiteSubscriptionViewController, context: Context) -> CGSize? {
        return CGSize(width: 320, height: 434)
    }
}

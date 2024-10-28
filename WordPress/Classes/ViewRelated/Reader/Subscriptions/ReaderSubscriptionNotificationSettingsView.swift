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

extension NotificationSiteSubscriptionViewController {
    static func show(
        forSiteID siteID: Int,
        sourceItem: UIPopoverPresentationControllerSourceItem,
        from presentingViewController: UIViewController
    ) {
        let isCompact = presentingViewController.traitCollection.horizontalSizeClass == .compact
        let settingsVC = NotificationSiteSubscriptionViewController(siteId: siteID)
        if isCompact {
            settingsVC.navigationItem.rightBarButtonItem = UIBarButtonItem(title: SharedStrings.Button.done, primaryAction: .init { [weak presentingViewController] _ in
                presentingViewController?.dismiss(animated: true)
            })
            let navigationVC = UINavigationController(rootViewController: settingsVC)
            navigationVC.sheetPresentationController?.detents = [.medium(), .large()]
            presentingViewController.present(navigationVC, animated: true)
        } else {
            settingsVC.preferredContentSize = CGSize(width: 320, height: 434)
            settingsVC.modalPresentationStyle = .popover
            settingsVC.popoverPresentationController?.sourceItem = sourceItem
            presentingViewController.present(settingsVC, animated: true)
        }
    }
}

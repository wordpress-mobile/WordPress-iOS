import UIKit
import SwiftUI
import WordPressKit

/// Coordinator to handle navigation from SwiftUI ActivityLogDetailsView to UIKit view controllers
enum ActivityLogDetailsCoordinator {

    static func presentRestore(activity: Activity, blog: Blog) {
        guard let viewController = UIViewController.topViewController,
              let siteRef = JetpackSiteRef(blog: blog),
              activity.isRewindable,
              activity.rewindID != nil else {
            return
        }

        // Check if the store has the credentials status cached
        let store = StoreContainer.shared.activity
        let isAwaitingCredentials = store.isAwaitingCredentials(site: siteRef)

        let restoreViewController = JetpackRestoreOptionsViewController(
            site: siteRef,
            activity: activity,
            isAwaitingCredentials: isAwaitingCredentials
        )

        restoreViewController.presentedFrom = "activity_detail"

        let navigationController = UINavigationController(rootViewController: restoreViewController)
        navigationController.modalPresentationStyle = .formSheet

        viewController.present(navigationController, animated: true)
    }

    static func presentBackup(activity: Activity, blog: Blog) {
        guard let viewController = UIViewController.topViewController,
              let siteRef = JetpackSiteRef(blog: blog) else {
            return
        }

        let backupViewController = JetpackBackupOptionsViewController(
            site: siteRef,
            activity: activity
        )

        backupViewController.presentedFrom = "activity_detail"

        let navigationController = UINavigationController(rootViewController: backupViewController)
        navigationController.modalPresentationStyle = .formSheet

        viewController.present(navigationController, animated: true)
    }
}

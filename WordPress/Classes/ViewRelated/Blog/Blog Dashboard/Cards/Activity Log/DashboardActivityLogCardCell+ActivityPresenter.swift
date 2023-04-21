import Foundation

// MARK: - ActivityPresenter

extension DashboardActivityLogCardCell: ActivityPresenter {

    func presentDetailsFor(activity: FormattableActivity) {
        guard
            let blog,
            let site = JetpackSiteRef(blog: blog),
            let presentingViewController else {
            return
        }

        let detailVC = ActivityDetailViewController.loadFromStoryboard()
        detailVC.site = site
        detailVC.rewindStatus = store.state.rewindStatus[site]
        detailVC.formattableActivity = activity
        detailVC.presenter = self

        presentingViewController.navigationController?.pushViewController(detailVC, animated: true)
    }

    func presentBackupOrRestoreFor(activity: Activity, from sender: UIButton) {
        // Do nothing - this action isn't available for the activity log dashboard card
    }

    func presentBackupFor(activity: Activity, from: String?) {
        guard
            let blog,
            let site = JetpackSiteRef(blog: blog),
            let presentingViewController else {
            return
        }

        let backupOptionsVC = JetpackBackupOptionsViewController(site: site, activity: activity)
        backupOptionsVC.presentedFrom = from ?? "dashboard"
        let navigationVC = UINavigationController(rootViewController: backupOptionsVC)
        presentingViewController.present(navigationVC, animated: true)
    }

    func presentRestoreFor(activity: Activity, from: String?) {
        guard activity.isRewindable, activity.rewindID != nil else {
            return
        }

        guard
            let blog,
            let site = JetpackSiteRef(blog: blog),
            let presentingViewController else {
            return
        }

        let restoreOptionsVC = JetpackRestoreOptionsViewController(site: site,
                                                                   activity: activity,
                                                                   isAwaitingCredentials: store.isAwaitingCredentials(site: site))

        restoreOptionsVC.restoreStatusDelegate = self
        restoreOptionsVC.presentedFrom = from ?? "dashboard"
        let navigationVC = UINavigationController(rootViewController: restoreOptionsVC)
        presentingViewController.present(navigationVC, animated: true)
    }
}

// MARK: - JetpackRestoreStatusViewControllerDelegate

extension DashboardActivityLogCardCell: JetpackRestoreStatusViewControllerDelegate {

    func didFinishViewing(_ controller: JetpackRestoreStatusViewController) {
        controller.dismiss(animated: true)
    }
}

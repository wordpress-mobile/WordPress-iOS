import Foundation

class BackupListViewController: ActivityListViewController {
    override init(site: JetpackSiteRef, store: ActivityStore, isFreeWPCom: Bool = false) {
        store.onlyRestorableItems = true

        let activityListConfiguration = ActivityListConfiguration(
            title: NSLocalizedString("Backup", comment: "Title for the Jetpack's backup list")
        )

        super.init(site: site, store: store, configuration: activityListConfiguration, isFreeWPCom: isFreeWPCom)

        activityTypeFilterChip.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        WPAnalytics.track(.backupListOpened)
    }
}

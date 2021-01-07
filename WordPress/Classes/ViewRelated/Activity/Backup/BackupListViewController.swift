import Foundation

class BackupListViewController: ActivityListViewController {
    override init(site: JetpackSiteRef, store: ActivityStore, isFreeWPCom: Bool = false) {
        store.onlyRestorableItems = true

        super.init(site: site, store: store, isFreeWPCom: isFreeWPCom)

        title = NSLocalizedString("Backup", comment: "Title for the Jetpack's backup list")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

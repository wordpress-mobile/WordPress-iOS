import Foundation

class BackupListViewController: ActivityListViewController {
    override init(site: JetpackSiteRef, store: ActivityStore, isFreeWPCom: Bool = false) {
        super.init(site: site, store: store, isFreeWPCom: isFreeWPCom)

        self.viewModel = ActivityListViewModel(site: site, store: store, onlyRewindableItems: true)

        self.changeReceipt = viewModel.onChange { [weak self] in
            self?.refreshModel()
        }

        title = NSLocalizedString("Backup", comment: "Title for the Jetpack's backup list")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

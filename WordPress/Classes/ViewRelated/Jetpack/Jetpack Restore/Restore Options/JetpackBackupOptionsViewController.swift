import UIKit
import CocoaLumberjack
import Gridicons
import WordPressFlux
import WordPressUI
import WordPressShared

class JetpackBackupOptionsViewController: BaseRestoreOptionsViewController {

    // MARK: - Properties

    private lazy var coordinator: JetpackBackupOptionsCoordinator = {
        return JetpackBackupOptionsCoordinator(site: self.site,
                                               store: self.store,
                                               restoreTypes: self.restoreTypes,
                                               view: self)
    }()

    // MARK: - Initialization

    override init(site: JetpackSiteRef, activity: Activity, store: ActivityStore) {
        let restoreOptionsConfiguration = JetpackRestoreOptionsConfiguration(
            title: NSLocalizedString("Download Backup", comment: "Title for the Jetpack Download Backup Site Screen"),
            iconImage: UIImage.gridicon(.history),
            messageTitle: NSLocalizedString("Create downloadable backup", comment: "Label that describes the download backup action"),
            messageDescription: NSLocalizedString("%1$@ is the selected point to create a downloadable backup.", comment: "Description for the download backup action. $1$@ is a placeholder for the selected date."),
            generalSectionHeaderText: NSLocalizedString("Choose the items to download", comment: "Downloadable items: general section title"),
            buttonTitle: NSLocalizedString("Create downloadable file", comment: "Button title for download backup action")
        )
        super.init(site: site, activity: activity, store: store, configuration: restoreOptionsConfiguration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Override

    override func actionButtonTapped() {
        coordinator.prepareBackup()
    }
}

extension JetpackBackupOptionsViewController: JetpackBackupOptionsView {

    func showNoInternetConnection() {
        ReachabilityUtils.showAlertNoInternetConnection()
    }

    func showBackupRequestFailed() {
        let errorTitle = NSLocalizedString("Backup failed", comment: "Title for error displayed when preparing a backup fails.")
        let errorMessage = NSLocalizedString("We couldn't create your backup. Please try again later.", comment: "Message for error displayed when preparing a backup fails.")
        let notice = Notice(title: errorTitle, message: errorMessage)
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    func showBackupStarted(for downloadID: Int) {
        let statusVC = JetpackBackupStatusViewController(site: site, activity: activity, store: store, downloadID: downloadID)
        self.navigationController?.pushViewController(statusVC, animated: true)
    }

}

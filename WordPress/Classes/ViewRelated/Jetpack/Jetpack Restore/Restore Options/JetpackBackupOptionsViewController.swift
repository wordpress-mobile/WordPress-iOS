import UIKit
import CocoaLumberjack
import Gridicons
import WordPressFlux
import WordPressUI
import WordPressShared

class JetpackBackupOptionsViewController: BaseRestoreOptionsViewController {

    // MARK: - Properties

    weak var backupStatusDelegate: JetpackBackupStatusViewControllerDelegate?

    // MARK: - Private Properties

    private lazy var coordinator: JetpackBackupOptionsCoordinator = {
        return JetpackBackupOptionsCoordinator(site: self.site,
                                               rewindID: self.activity.rewindID,
                                               restoreTypes: self.restoreTypes,
                                               view: self)
    }()

    // MARK: - Initialization

    override init(site: JetpackSiteRef, activity: Activity) {
        let restoreOptionsConfiguration = JetpackRestoreOptionsConfiguration(
            title: NSLocalizedString("Download Backup", comment: "Title for the Jetpack Download Backup Site Screen"),
            iconImage: UIImage.gridicon(.history),
            messageTitle: NSLocalizedString("Create downloadable backup", comment: "Label that describes the download backup action"),
            messageDescription: NSLocalizedString("%1$@ is the selected point to create a downloadable backup.", comment: "Description for the download backup action. $1$@ is a placeholder for the selected date."),
            generalSectionHeaderText: NSLocalizedString("Choose the items to download", comment: "Downloadable items: general section title"),
            buttonTitle: NSLocalizedString("Create downloadable file", comment: "Button title for download backup action"),
            warningButtonTitle: nil,
            isRestoreTypesConfigurable: true
        )
        super.init(site: site, activity: activity, configuration: restoreOptionsConfiguration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        WPAnalytics.track(.backupDownloadOpened, properties: ["source": presentedFrom])
    }

    // MARK: - Override

    override func actionButtonTapped() {
        WPAnalytics.track(.backupDownloadConfirmed, properties: ["restore_types": [
            "themes": restoreTypes.themes,
            "plugins": restoreTypes.plugins,
            "uploads": restoreTypes.uploads,
            "sqls": restoreTypes.sqls,
            "roots": restoreTypes.roots,
            "contents": restoreTypes.contents
        ]])

        coordinator.prepareBackup()
    }
}

extension JetpackBackupOptionsViewController: JetpackBackupOptionsView {

    func showNoInternetConnection() {
        ReachabilityUtils.showAlertNoInternetConnection()
        WPAnalytics.track(.backupFileDownloadError, properties: ["cause": "offline"])
    }

    func showBackupAlreadyRunning() {
        let title = NSLocalizedString("There's a backup currently being prepared, please wait before starting the next one", comment: "Text displayed when user tries to create a downloadable backup when there is already one being prepared")
        let notice = Notice(title: title)
        ActionDispatcher.dispatch(NoticeAction.post(notice))
        WPAnalytics.track(.backupFileDownloadError, properties: ["cause": "other"])
    }

    func showBackupRequestFailed() {
        let errorTitle = NSLocalizedString("Backup failed", comment: "Title for error displayed when preparing a backup fails.")
        let errorMessage = NSLocalizedString("We couldn't create your backup. Please try again later.", comment: "Message for error displayed when preparing a backup fails.")
        let notice = Notice(title: errorTitle, message: errorMessage)
        ActionDispatcher.dispatch(NoticeAction.post(notice))
        WPAnalytics.track(.backupFileDownloadError, properties: ["cause": "remote"])
    }

    func showBackupStarted(for downloadID: Int) {
        let statusVC = JetpackBackupStatusViewController(site: site,
                                                         activity: activity,
                                                         downloadID: downloadID)
        statusVC.delegate = backupStatusDelegate
        self.navigationController?.pushViewController(statusVC, animated: true)
    }

}

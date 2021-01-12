import Foundation
import CocoaLumberjack
import Gridicons
import WordPressUI
import WordPressShared

class JetpackDownloadBackupViewController: BaseRestoreOptionsViewController {

    // MARK: - Initialization

    override init(site: JetpackSiteRef, activity: FormattableActivity) {
        let restoreOptionsConfiguration = JetpackRestoreOptionsConfiguration(
            title: NSLocalizedString("Download Backup", comment: "Title for the Jetpack Download Backup Site Screen"),
            iconImage: UIImage.gridicon(.history),
            messageTitle: NSLocalizedString("Create downloadable backup", comment: "Label that describes the download backup action"),
            messageDescription: NSLocalizedString("%1$@ is the selected point to create a downloadable backup.", comment: "Description for the download backup action. $1$@ is a placeholder for the selected date."),
            generalSectionHeaderText: NSLocalizedString("Choose the items to download", comment: "Downloadable items: general section title"),
            buttonTitle: NSLocalizedString("Create downloadable file", comment: "Button title for download backup action")
        )
        super.init(site: site, activity: activity, configuration: restoreOptionsConfiguration)
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
        let statusVC = JetpackBackupStatusViewController(site: site,
                                                         activity: formattableActivity.activity,
                                                         restoreTypes: JetpackRestoreTypes())
        self.navigationController?.pushViewController(statusVC, animated: true)
    }

}

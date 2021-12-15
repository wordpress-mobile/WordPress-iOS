import UIKit
import CocoaLumberjack
import WordPressShared
import WordPressUI

class JetpackBackupStatusFailedViewController: BaseRestoreStatusFailedViewController {

    // MARK: - Initialization

    override init() {
        let configuration = RestoreStatusFailedConfiguration(
            title: AppLocalizedString("Backup", comment: "Title for Jetpack Backup Update Status Failed screen"),
            messageTitle: AppLocalizedString("Hmm, we couldn’t find your backup status", comment: "Message title displayed when we fail to fetch the status of the backup in progress."),
            firstHint: AppLocalizedString("We couldn’t find the status to say how long your backup will take.", comment: "Hint displayed when we fail to fetch the status of the backup in progress."),
            secondHint: AppLocalizedString("We’ll still attempt to backup your site.", comment: "Hint displayed when we fail to fetch the status of the backup in progress."),
            thirdHint: AppLocalizedString("We’ll notify you when its done.", comment: "Hint displayed when we fail to fetch the status of the backup in progress.")
        )
        super.init(configuration: configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}

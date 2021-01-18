import Foundation
import CocoaLumberjack
import WordPressShared
import WordPressUI

class JetpackBackupCompleteViewController: BaseRestoreCompleteViewController {

    // MARK: - Initialization

    override init(site: JetpackSiteRef, activity: Activity) {
        let restoreCompleteConfiguration = JetpackRestoreCompleteConfiguration(
            title: NSLocalizedString("Backup", comment: "Title for Jetpack Backup Complete screen"),
            iconImage: .gridicon(.history),
            messageTitle: NSLocalizedString("Your backup is now available for download", comment: "Title for the Jetpack Backup Complete message."),
            messageDescription: NSLocalizedString("We successfully created a backup of your site from %1$@.", comment: "Description for the Jetpack Backup Complete message. %1$@ is a placeholder for the selected date."),
            hint: NSLocalizedString("We've also emailed you a link to your file.", comment: "A hint to users indicating a link to the downloadable backup file has also been sent to their email."),
            primaryButtonTitle: NSLocalizedString("Download file", comment: "Title for the button that will download the backup file."),
            secondaryButtonTitle: NSLocalizedString("Share link", comment: "Title for the button that will share the link for the downlodable backup file")
        )
        super.init(site: site, activity: activity, configuration: restoreCompleteConfiguration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}

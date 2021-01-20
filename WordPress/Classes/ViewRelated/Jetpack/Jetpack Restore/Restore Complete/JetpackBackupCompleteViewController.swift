import UIKit
import CocoaLumberjack
import WordPressShared
import WordPressUI

class JetpackBackupCompleteViewController: BaseRestoreCompleteViewController {

    private let backup: JetpackBackup

    // MARK: - Initialization

    init(site: JetpackSiteRef, activity: Activity, backup: JetpackBackup) {
        self.backup = backup

        let restoreCompleteConfiguration = JetpackRestoreCompleteConfiguration(
            isSuccess: true,
            title: NSLocalizedString("Backup", comment: "Title for Jetpack Backup Complete screen"),
            iconImage: .gridicon(.history),
            messageTitle: NSLocalizedString("Your backup is now available for download", comment: "Title for the Jetpack Backup Complete message."),
            messageDescription: NSLocalizedString("We successfully created a backup of your site from %1$@.", comment: "Description for the Jetpack Backup Complete message. %1$@ is a placeholder for the selected date."),
            primaryButtonTitle: NSLocalizedString("Download file", comment: "Title for the button that will download the backup file."),
            secondaryButtonTitle: NSLocalizedString("Share link", comment: "Title for the button that will share the link for the downlodable backup file"),
            hint: NSLocalizedString("We've also emailed you a link to your file.", comment: "A hint to users indicating a link to the downloadable backup file has also been sent to their email.")
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

    // MARK: - Override

    override func primaryButtonTapped() {
        downloadFile()
    }

    override func secondaryButtonTapped() {
        shareLink()
    }

    // MARK: - Private

    private func downloadFile() {
        // TODO
    }

    private func shareLink() {
        guard let url = backup.url,
              let downloadURL = URL(string: url),
              let activities = WPActivityDefaults.defaultActivities() as? [UIActivity] else {
            return
        }

        let activityVC = UIActivityViewController(activityItems: [downloadURL], applicationActivities: activities)
        activityVC.popoverPresentationController?.sourceView = self.view

        self.present(activityVC, animated: true)
    }

}

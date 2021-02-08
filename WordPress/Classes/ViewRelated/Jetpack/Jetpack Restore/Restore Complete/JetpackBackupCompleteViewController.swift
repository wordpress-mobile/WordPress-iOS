import UIKit
import CocoaLumberjack
import WordPressFlux
import WordPressShared
import WordPressUI

class JetpackBackupCompleteViewController: BaseRestoreCompleteViewController {

    private let backup: JetpackBackup

    // MARK: - Initialization

    init(site: JetpackSiteRef, activity: Activity, backup: JetpackBackup) {
        self.backup = backup

        let restoreCompleteConfiguration = JetpackRestoreCompleteConfiguration(
            title: NSLocalizedString("Backup", comment: "Title for Jetpack Backup Complete screen"),
            iconImage: .gridicon(.history),
            iconImageColor: .success,
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
        WPAnalytics.track(.backupFileDownloadTapped)
    }

    override func secondaryButtonTapped(from sender: UIButton) {
        shareLink(from: sender)
        WPAnalytics.track(.backupDownloadShareLinkTapped)
    }

    // MARK: - Private

    private func downloadFile() {
        guard let url = backup.url,
              let downloadURL = URL(string: url) else {

            let title = NSLocalizedString("Unable to download file", comment: "Message displayed when opening the link to the downloadable backup fails.")
            let notice = Notice(title: title)
            ActionDispatcher.dispatch(NoticeAction.post(notice))

            return
        }

        UIApplication.shared.open(downloadURL)
    }

    private func shareLink(from sender: UIButton) {
        guard let url = backup.url,
              let downloadURL = URL(string: url),
              let activities = WPActivityDefaults.defaultActivities() as? [UIActivity] else {

            let title = NSLocalizedString("Unable to share link", comment: "Message displayed when sharing a link to the downloadable backup fails.")
            let notice = Notice(title: title)
            ActionDispatcher.dispatch(NoticeAction.post(notice))

            return
        }

        let activityVC = UIActivityViewController(activityItems: [downloadURL], applicationActivities: activities)
        activityVC.popoverPresentationController?.sourceView = sender
        activityVC.modalPresentationStyle = .popover


        self.present(activityVC, animated: true)
    }

}

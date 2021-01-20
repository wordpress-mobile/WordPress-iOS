import UIKit
import CocoaLumberjack
import WordPressShared
import WordPressUI

class JetpackBackupFailedViewController: BaseRestoreCompleteViewController {

    // MARK: - Initialization

    override init(site: JetpackSiteRef, activity: Activity) {
        let restoreCompleteConfiguration = JetpackRestoreCompleteConfiguration(
            isSuccess: false,
            title: NSLocalizedString("Backup failed", comment: "Title for Jetpack Backup Failed screen"),
            iconImage: .gridicon(.notice),
            messageTitle: NSLocalizedString("Unable to create a backup for your site", comment: "Title for the Jetpack Backup Failed message."),
            messageDescription: NSLocalizedString("Please try again later or contact support.", comment: "Description for the Jetpack Backup Failed message."),
            primaryButtonTitle: NSLocalizedString("Done", comment: "Title for the button that will dismiss this view."),
            secondaryButtonTitle: nil,
            hint: nil
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
        self.dismiss(animated: true)
    }

}

import UIKit
import CocoaLumberjack
import WordPressShared
import WordPressUI

class JetpackBackupStatusFailedViewController: BaseRestoreCompleteViewController {

    // MARK: - Initialization

    override init(site: JetpackSiteRef, activity: Activity) {
        let restoreCompleteConfiguration = JetpackRestoreCompleteConfiguration(
            title: NSLocalizedString("Status Update Failed", comment: "Title for Jetpack Backup Status Failed screen"),
            iconImage: .gridicon(.notice),
            iconImageColor: .error,
            messageTitle: NSLocalizedString("Hmm, we can't update the status of your backup.", comment: "Title for the Jetpack Backup Status Failed message."),
            messageDescription: "No need to worry. We'll notify you when your backup is ready.",  // FIXME: Placholder text
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

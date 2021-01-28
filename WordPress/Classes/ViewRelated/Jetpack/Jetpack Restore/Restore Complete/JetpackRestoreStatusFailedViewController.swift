import UIKit
import CocoaLumberjack
import WordPressShared
import WordPressUI

class JetpackRestoreStatusFailedViewController: BaseRestoreCompleteViewController {

    // MARK: - Initialization

    override init(site: JetpackSiteRef, activity: Activity) {
        let restoreCompleteConfiguration = JetpackRestoreCompleteConfiguration(
            title: NSLocalizedString("Status Update Failed", comment: "Title for Jetpack Restore Status Failed screen"),
            iconImage: .gridicon(.notice),
            iconImageColor: .error,
            messageTitle: NSLocalizedString("Hmm, we can't update the status of your restore", comment: "Message title displayed when we fail to fetch the status of the restore in progress."),
            messageDescription: NSLocalizedString("We couldn't find the status to say how long your restore will take.", comment: "Message description displayed when we fail to fetch the status of the restore in progress."),
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

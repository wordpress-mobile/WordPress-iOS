import UIKit
import CocoaLumberjack
import WordPressShared
import WordPressUI

class JetpackRestoreStatusFailedViewController: BaseRestoreStatusFailedViewController {

    // MARK: - Initialization

    override init() {
        let configuration = RestoreStatusFailedConfiguration(
            title: NSLocalizedString("Restore", comment: "Title for Jetpack Restore Status Failed screen"),
            messageTitle: NSLocalizedString("Hmm, we couldn’t find your restore status", comment: "Message title displayed when we fail to fetch the status of the restore in progress."),
            firstHint: NSLocalizedString("We couldn’t find the status to say how long your restore will take.", comment: "Hint displayed when we fail to fetch the status of the restore in progress."),
            secondHint: NSLocalizedString("We’ll still attempt to restore your site.", comment: "Hint displayed when we fail to fetch the status of the restore in progress."),
            thirdHint: NSLocalizedString("We’ll notify you when its done.", comment: "Hint displayed when we fail to fetch the status of the restore in progress.")
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

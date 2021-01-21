import UIKit
import CocoaLumberjack
import WordPressShared
import WordPressUI

class JetpackRestoreFailedViewController: BaseRestoreCompleteViewController {

    // MARK: - Initialization

    override init(site: JetpackSiteRef, activity: Activity) {
        let restoreCompleteConfiguration = JetpackRestoreCompleteConfiguration(
            title: NSLocalizedString("Restore Failed", comment: "Title for Jetpack Restore Failed screen"),
            iconImage: .gridicon(.notice),
            iconImageColor: .error,
            messageTitle: NSLocalizedString("Unable to restore your site", comment: "Title for the Jetpack Restore Failed message."),
            messageDescription: NSLocalizedString("Please try again later or contact support.", comment: "Description for the Jetpack Restore Failed message."),
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

import Foundation
import CocoaLumberjack
import WordPressShared
import WordPressUI

class JetpackRestoreCompleteViewController: BaseRestoreCompleteViewController {

    // MARK: - Initialization

    override init(site: JetpackSiteRef, activity: Activity) {
        let restoreCompleteConfiguration = JetpackRestoreCompleteConfiguration(
            title: NSLocalizedString("Restore", comment: "Title for Jetpack Restore Complete screen"),
            iconImage: .gridicon(.history),
            messageTitle: NSLocalizedString("Your site has been restored", comment: "Title for the Jetpack Restore Complete message."),
            messageDescription: NSLocalizedString("All of your selected items are now restored back to %1$@.", comment: "Description for the Jetpack Backup Restore message. %1$@ is a placeholder for the selected date."),
            primaryButtonTitle: NSLocalizedString("Done", comment: "Title for the button that will dismiss this view."),
            secondaryButtonTitle: NSLocalizedString("Visit site", comment: "Title for the button that will open a link to this site."),
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

    override func secondaryButtonTapped() {
        // TODO: visit site
    }

}

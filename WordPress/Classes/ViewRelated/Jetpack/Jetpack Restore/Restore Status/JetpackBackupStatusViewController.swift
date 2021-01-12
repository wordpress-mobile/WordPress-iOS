import Foundation
import CocoaLumberjack
import WordPressShared
import WordPressUI

class JetpackBackupStatusViewController: BaseRestoreStatusViewController {

    // MARK: - Initialization

    override init(site: JetpackSiteRef, activity: Activity, restoreTypes: JetpackRestoreTypes) {
        let restoreStatusConfiguration = JetpackRestoreStatusConfiguration(
            title: NSLocalizedString("Backup", comment: "Title for Jetpack Backup Status screen"),
            iconImage: .gridicon(.history),
            messageTitle: NSLocalizedString("Currently creating a downloadable backup of you site", comment: "Title for the Jetpack Restore Status screen."),
            messageDescription: NSLocalizedString("We're creating a downloadable backup of your site from %1$@.", comment: "Description for the restore action. %1$@ is a placeholder for the selected date."),
            hint: NSLocalizedString("No need to wait around. We'll notify you when your backup is ready.", comment: "A hint to users about restoring their site."),
            primaryButtonTitle: NSLocalizedString("OK, notify me!", comment: "Title for the button that will dismiss this view.")
        )
        super.init(site: site, activity: activity, restoreTypes: restoreTypes, configuration: restoreStatusConfiguration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}

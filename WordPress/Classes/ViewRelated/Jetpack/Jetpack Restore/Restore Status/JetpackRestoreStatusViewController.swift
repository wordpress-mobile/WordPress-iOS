import Foundation
import CocoaLumberjack
import WordPressShared
import WordPressUI

class JetpackRestoreStatusViewController: BaseRestoreStatusViewController {

    // MARK: - Initialization

    override init(site: JetpackSiteRef, activity: Activity, restoreTypes: JetpackRestoreTypes) {
           let restoreStatusConfiguration = JetpackRestoreStatusConfiguration(
               title: NSLocalizedString("Restore", comment: "Title for Jetpack Restore Status screen"),
               iconImage: .gridicon(.history),
               messageTitle: NSLocalizedString("Currently restoring site", comment: "Title for the Jetpack Restore Status message."),
               messageDescription: NSLocalizedString("We're restoring your site back to %1$@.", comment: "Description for the Jetpack Restore Status message. %1$@ is a placeholder for the selected date."),
               hint: NSLocalizedString("No need to wait around. We'll notify you when your site has been fully restored.", comment: "A hint to users about restoring their site."),
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

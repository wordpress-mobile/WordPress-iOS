import Foundation
import CocoaLumberjack
import Gridicons
import WordPressUI
import WordPressShared

class JetpackRestoreOptionsViewController: BaseRestoreOptionsViewController {

    // MARK: - Properties

    weak var restoreStatusDelegate: JetpackRestoreStatusViewControllerDelegate?

    // MARK: - Initialization

    override init(site: JetpackSiteRef, activity: Activity) {
        let restoreOptionsConfiguration = JetpackRestoreOptionsConfiguration(
            title: NSLocalizedString("Restore", comment: "Title for the Jetpack Restore Site Screen"),
            iconImage: UIImage.gridicon(.history),
            messageTitle: NSLocalizedString("Restore site", comment: "Label that describes the restore site action"),
            messageDescription: NSLocalizedString("%1$@ is the selected point for your restore.", comment: "Description for the restore action. $1$@ is a placeholder for the selected date."),
            generalSectionHeaderText: NSLocalizedString("Choose the items to restore", comment: "Restorable items: general section title"),
            buttonTitle: NSLocalizedString("Restore to this point", comment: "Button title for restore site action")
        )
        super.init(site: site, activity: activity, configuration: restoreOptionsConfiguration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Override

    override func actionButtonTapped() {
        let warningVC = JetpackRestoreWarningViewController(site: site,
                                                            activity: activity,
                                                            restoreTypes: restoreTypes)
        warningVC.restoreStatusDelegate = restoreStatusDelegate
        self.navigationController?.pushViewController(warningVC, animated: true)
    }

}

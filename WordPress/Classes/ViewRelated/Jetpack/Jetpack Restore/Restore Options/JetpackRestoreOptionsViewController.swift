import Foundation
import CocoaLumberjack
import Gridicons
import WordPressUI
import WordPressShared

class JetpackRestoreOptionsViewController: BaseRestoreOptionsViewController {

    // MARK: - Properties

    weak var restoreStatusDelegate: JetpackRestoreStatusViewControllerDelegate?

    // MARK: - Private Property

    private let isAwaitingCredentials: Bool

    // MARK: - Initialization

    init(site: JetpackSiteRef, activity: Activity, isAwaitingCredentials: Bool) {
        let restoreOptionsConfiguration = JetpackRestoreOptionsConfiguration(
            title: NSLocalizedString("Restore", comment: "Title for the Jetpack Restore Site Screen"),
            iconImage: UIImage.gridicon(.history),
            messageTitle: NSLocalizedString("Restore site", comment: "Label that describes the restore site action"),
            messageDescription: NSLocalizedString("%1$@ is the selected point for your restore.", comment: "Description for the restore action. $1$@ is a placeholder for the selected date."),
            generalSectionHeaderText: NSLocalizedString("Choose the items to restore", comment: "Restorable items: general section title"),
            buttonTitle: NSLocalizedString("Restore to this point", comment: "Button title for restore site action"),
            warningButtonTitle: isAwaitingCredentials ? NSLocalizedString("Enter your server credentials to enable one click site restores from backups.", comment: "Error message displayed when restoring a site fails due to credentials not being configured.") : nil,
            isRestoreTypesConfigurable: !isAwaitingCredentials
        )

        self.isAwaitingCredentials = isAwaitingCredentials

        super.init(site: site, activity: activity, configuration: restoreOptionsConfiguration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        WPAnalytics.track(.restoreOpened, properties: ["source": presentedFrom])
    }

    // MARK: - Override

    override func actionButtonTapped() {
        let warningVC = JetpackRestoreWarningViewController(site: site,
                                                            activity: activity,
                                                            restoreTypes: restoreTypes)
        warningVC.restoreStatusDelegate = restoreStatusDelegate
        self.navigationController?.pushViewController(warningVC, animated: true)
    }

    override func detailActionButtonTapped() {
        guard let jetpackSettingsURL = URL(string: "https://wordpress.com/settings/jetpack/\(site.siteID)") else {

            let title = NSLocalizedString("Unable to visit Jetpack settings for site", comment: "Message displayed when visiting the Jetpack settings page fails.")

            displayNotice(title: title)

            return
        }

        let webVC = WebViewControllerFactory.controller(url: jetpackSettingsURL)
        let navigationVC = UINavigationController(rootViewController: webVC)

        present(navigationVC, animated: true)
    }

}

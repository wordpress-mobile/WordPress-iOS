import Foundation
import CocoaLumberjack
import WordPressShared
import WordPressUI

class JetpackBackupStatusViewController: BaseRestoreStatusViewController {

    // MARK: - Properties

    private lazy var coordinator: JetpackBackupStatusCoordinator = {
        return JetpackBackupStatusCoordinator(site: self.site, view: self)
    }()

    // MARK: - Initialization

    override init(site: JetpackSiteRef, activity: Activity, restoreTypes: JetpackRestoreTypes) {
        let restoreStatusConfiguration = JetpackRestoreStatusConfiguration(
            title: NSLocalizedString("Backup", comment: "Title for Jetpack Backup Status screen"),
            iconImage: .gridicon(.history),
            messageTitle: NSLocalizedString("Currently creating a downloadable backup of your site", comment: "Title for the Jetpack Backup Status message."),
            messageDescription: NSLocalizedString("We're creating a downloadable backup of your site from %1$@.", comment: "Description for the Jetpack Backup Status message. %1$@ is a placeholder for the selected date."),
            hint: NSLocalizedString("No need to wait around. We'll notify you when your backup is ready.", comment: "A hint to users about creating a downloadable backup of their site."),
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
        coordinator.start()
    }

}

extension JetpackBackupStatusViewController: JetpackBackupStatusView {

    func render(_ backup: JetpackBackup) {
        guard let progress = backup.progress else {
            return
        }

        statusView.update(progress: progress)
    }

    func showError() {
        // TODO
    }

    func showComplete() {
        let completeVC = JetpackBackupCompleteViewController(site: site, activity: activity)
        self.navigationController?.pushViewController(completeVC, animated: true)
    }
}

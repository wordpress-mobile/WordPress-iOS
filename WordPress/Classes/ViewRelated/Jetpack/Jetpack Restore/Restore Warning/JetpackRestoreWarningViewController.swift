import UIKit
import CocoaLumberjack
import WordPressFlux
import WordPressShared

class JetpackRestoreWarningViewController: UIViewController {

    // MARK: - Properties

    private lazy var coordinator: JetpackRestoreWarningCoordinator = {
        return JetpackRestoreWarningCoordinator(site: self.site,
                                                store: self.store,
                                                restoreTypes: self.restoreTypes,
                                                rewindID: self.activity.rewindID,
                                                view: self)
    }()

    // MARK: - Private Properties

    private let site: JetpackSiteRef
    private let activity: Activity
    private let store: ActivityStore
    private let restoreTypes: JetpackRestoreTypes

    private lazy var dateFormatter: DateFormatter = {
        return ActivityDateFormatting.mediumDateFormatterWithTime(for: site)
    }()

    // MARK: - Initialization

    init(site: JetpackSiteRef,
         activity: Activity,
         store: ActivityStore,
         restoreTypes: JetpackRestoreTypes) {
        self.site = site
        self.activity = activity
        self.store = store
        self.restoreTypes = restoreTypes
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Warning", comment: "Title for Jetpack Restore Warning screen")
        configureWarningView()
    }

    // MARK: - Configure

    private func configureWarningView() {
        let warningView = RestoreWarningView.loadFromNib()
        let publishedDate = dateFormatter.string(from: activity.published)
        warningView.configure(with: publishedDate)

        warningView.confirmHandler = { [weak self] in
            self?.coordinator.restoreSite()
        }

        warningView.cancelHandler = { [weak self] in
            self?.dismiss(animated: true)
        }

        warningView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(warningView)
        view.pinSubviewToAllEdges(warningView)
    }

}

extension JetpackRestoreWarningViewController: JetpackRestoreWarningView {

    func showNoInternetConnection() {
        ReachabilityUtils.showAlertNoInternetConnection()
    }

    func showRestoreAlreadyRunning() {
        self.dismiss(animated: true, completion: { [weak self] in
            guard let self = self else {
                return
            }

            let action = ActivityAction.rewindRequestFailed(site: self.site, error: ActivityStoreError.rewindAlreadyRunning)
            self.store.actionDispatcher.dispatch(action)
        })
    }

    func showRestoreRequestFailed() {
        let errorTitle = NSLocalizedString("Restore failed", comment: "Title for error displayed when restoring a site fails.")
        let errorMessage = NSLocalizedString("We couldn't restore your site. Please try again later.", comment: "Message for error displayed when restoring a site fails.")
        let notice = Notice(title: errorTitle, message: errorMessage)
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    func showRestoreStarted() {
        let statusVC = JetpackRestoreStatusViewController(site: site, activity: activity, store: store)
        self.navigationController?.pushViewController(statusVC, animated: true)
    }
}

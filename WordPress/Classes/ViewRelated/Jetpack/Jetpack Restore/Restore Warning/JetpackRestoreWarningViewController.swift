import UIKit
import CocoaLumberjack
import WordPressFlux
import WordPressShared

class JetpackRestoreWarningViewController: UIViewController {

    // MARK: - Properties

    weak var restoreStatusDelegate: JetpackRestoreStatusViewControllerDelegate?

    // MARK: - Private Properties

    private lazy var coordinator: JetpackRestoreWarningCoordinator = {
        return JetpackRestoreWarningCoordinator(site: self.site,
                                                restoreTypes: self.restoreTypes,
                                                rewindID: self.activity.rewindID,
                                                view: self)
    }()

    // MARK: - Private Properties

    private let site: JetpackSiteRef
    private let activity: Activity
    private let restoreTypes: JetpackRestoreTypes

    private lazy var dateFormatter: DateFormatter = {
        return ActivityDateFormatting.mediumDateFormatterWithTime(for: site)
    }()

    // MARK: - Initialization

    init(site: JetpackSiteRef,
         activity: Activity,
         restoreTypes: JetpackRestoreTypes) {
        self.site = site
        self.activity = activity
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
            guard let self = self else {
                return
            }

            WPAnalytics.track(.restoreConfirmed, properties: ["restore_types": [
                "themes": self.restoreTypes.themes,
                "plugins": self.restoreTypes.plugins,
                "uploads": self.restoreTypes.uploads,
                "sqls": self.restoreTypes.sqls,
                "roots": self.restoreTypes.roots,
                "contents": self.restoreTypes.contents
            ]])

            self.coordinator.restoreSite()
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
        WPAnalytics.track(.restoreError, properties: ["cause": "offline"])
    }

    func showRestoreAlreadyRunning() {
        let title = NSLocalizedString("There's a restore currently in progress, please wait before starting the next one", comment: "Text displayed when user tries to start a restore when there is already one running")
        let notice = Notice(title: title)
        ActionDispatcher.dispatch(NoticeAction.post(notice))
        WPAnalytics.track(.restoreError, properties: ["cause": "other"])
    }

    func showRestoreRequestFailed() {
        let errorTitle = NSLocalizedString("Restore failed", comment: "Title for error displayed when restoring a site fails.")
        let errorMessage = NSLocalizedString("We couldn't restore your site. Please try again later.", comment: "Message for error displayed when restoring a site fails.")
        let notice = Notice(title: errorTitle, message: errorMessage)
        ActionDispatcher.dispatch(NoticeAction.post(notice))
        WPAnalytics.track(.restoreError, properties: ["cause": "remote"])
    }

    func showRestoreStarted() {
        let statusVC = JetpackRestoreStatusViewController(site: site,
                                                          activity: activity)
        statusVC.delegate = restoreStatusDelegate
        self.navigationController?.pushViewController(statusVC, animated: true)
    }
}

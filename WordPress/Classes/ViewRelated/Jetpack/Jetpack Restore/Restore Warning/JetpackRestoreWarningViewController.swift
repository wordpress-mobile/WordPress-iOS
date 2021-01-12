import Foundation
import CocoaLumberjack
import WordPressShared

class JetpackRestoreWarningViewController: UIViewController {

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

    private func configureWarningView() {
        let warningView = RestoreWarningView.loadFromNib()

        warningView.confirmHandler = { [weak self] in
            guard let self = self else {
                return
            }
            let statusVC = JetpackRestoreStatusViewController(site: self.site,
                                                              activity: self.activity,
                                                              restoreTypes: self.restoreTypes)
            self.navigationController?.pushViewController(statusVC, animated: true)
        }

        warningView.cancelHandler = { [weak self] in
            self?.dismiss(animated: true)
        }

        warningView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(warningView)
        view.pinSubviewToAllEdges(warningView)
    }

}

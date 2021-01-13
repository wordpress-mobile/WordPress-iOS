import Foundation
import CocoaLumberjack
import WordPressShared

struct JetpackRestoreStatusConfiguration {
    let title: String
    let iconImage: UIImage
    let messageTitle: String
    let messageDescription: String
    let hint: String
    let primaryButtonTitle: String
}

class BaseRestoreStatusViewController: UIViewController {

    // MARK: - Private Properties

    private let site: JetpackSiteRef
    private let activity: Activity
    private let restoreTypes: JetpackRestoreTypes
    private let configuration: JetpackRestoreStatusConfiguration

    private lazy var dateFormatter: DateFormatter = {
        return ActivityDateFormatting.mediumDateFormatterWithTime(for: site)
    }()

    // MARK: - Initialization

    init(site: JetpackSiteRef,
         activity: Activity,
         restoreTypes: JetpackRestoreTypes) {
        fatalError("A configuration struct needs to be provided")
    }

    init(site: JetpackSiteRef,
         activity: Activity,
         restoreTypes: JetpackRestoreTypes,
         configuration: JetpackRestoreStatusConfiguration) {
        self.site = site
        self.activity = activity
        self.restoreTypes = restoreTypes
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTitle()
        configureNavigation()
        configureRestoreStatusView()
    }

    // MARK: - Configure

    private func configureTitle() {
        title = configuration.title
    }

    private func configureNavigation() {
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                           target: self,
                                                           action: #selector(doneTapped))
    }

    private func configureRestoreStatusView() {
        let statusView = RestoreStatusView.loadFromNib()
        let publishedDate = dateFormatter.string(from: activity.published)

        statusView.configure(
            iconImage: configuration.iconImage,
            title: configuration.messageTitle,
            description: String(format: configuration.messageDescription, publishedDate),
            primaryButtonTitle: configuration.primaryButtonTitle,
            hint: configuration.hint
        )

        statusView.primaryButtonHandler = { [weak self] in
            self?.dismiss(animated: true)
        }

        statusView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusView)
        view.pinSubviewToAllEdges(statusView)
    }

    @objc private func doneTapped() {
        self.dismiss(animated: true)
    }
}

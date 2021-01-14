import Foundation
import CocoaLumberjack
import WordPressShared

struct JetpackRestoreCompleteConfiguration {
    let title: String
    let iconImage: UIImage
    let messageTitle: String
    let messageDescription: String
    let hint: String
    let primaryButtonTitle: String
    let secondaryButtonTitle: String?
}

class BaseRestoreCompleteViewController: UIViewController {

    // MARK: - Private Properties

    private let site: JetpackSiteRef
    private let activity: Activity
    private let configuration: JetpackRestoreCompleteConfiguration

    private lazy var dateFormatter: DateFormatter = {
        return ActivityDateFormatting.mediumDateFormatterWithTime(for: site)
    }()

    // MARK: - Initialization

    init(site: JetpackSiteRef, activity: Activity) {
        fatalError("A configuration struct needs to be provided")
    }

    init(site: JetpackSiteRef,
         activity: Activity,
         configuration: JetpackRestoreCompleteConfiguration) {
        self.site = site
        self.activity = activity
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
        configureRestoreCompleteView()
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

    private func configureRestoreCompleteView() {
        let completeView = RestoreCompleteView.loadFromNib()
        let publishedDate = dateFormatter.string(from: activity.published)

        completeView.configure(
            iconImage: configuration.iconImage,
            title: configuration.messageTitle,
            description: String(format: configuration.messageDescription, publishedDate),
            hint: configuration.hint,
            primaryButtonTitle: configuration.primaryButtonTitle,
            secondaryButtonTitle: configuration.secondaryButtonTitle
        )

        completeView.primaryButtonHandler = {
            // TODO
        }

        completeView.secondaryButtonHandler = {
            // TODO
        }

        completeView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(completeView)
        view.pinSubviewToAllEdges(completeView)
    }

    @objc private func doneTapped() {
        self.dismiss(animated: true)
    }

}

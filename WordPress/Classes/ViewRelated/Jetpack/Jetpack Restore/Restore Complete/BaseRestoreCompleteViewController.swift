import Foundation
import CocoaLumberjack
import WordPressShared

struct JetpackRestoreCompleteConfiguration {
    let title: String
    let iconImage: UIImage
    let iconImageColor: UIColor
    let messageTitle: String
    let messageDescription: String
    let primaryButtonTitle: String?
    let secondaryButtonTitle: String?
    let hint: String?
}

class BaseRestoreCompleteViewController: UIViewController {

    // MARK: - Private Properties

    private(set) var site: JetpackSiteRef
    private let activity: Activity
    private let configuration: JetpackRestoreCompleteConfiguration

    private lazy var dateFormatter: DateFormatter = {
        return ActivityDateFormatting.mediumDateFormatterWithTime(for: site)
    }()

    private lazy var completeView: RestoreCompleteView = {
        let completeView = RestoreCompleteView.loadFromNib()
        completeView.translatesAutoresizingMaskIntoConstraints = false
        return completeView
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

    // MARK: - Public

    func primaryButtonTapped() {
        fatalError("Must override in subclass")
    }

    func secondaryButtonTapped(from sender: UIButton) {
        fatalError("Must override in subclass")
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
        let publishedDate = dateFormatter.string(from: activity.published)

        completeView.configure(
            iconImage: configuration.iconImage,
            iconImageColor: configuration.iconImageColor,
            title: configuration.messageTitle,
            description: String(format: configuration.messageDescription, publishedDate),
            primaryButtonTitle: configuration.primaryButtonTitle,
            secondaryButtonTitle: configuration.secondaryButtonTitle,
            hint: configuration.hint
        )

        completeView.primaryButtonHandler = { [weak self] in
            self?.primaryButtonTapped()
        }

        completeView.secondaryButtonHandler = { [weak self] sender in
            self?.secondaryButtonTapped(from: sender)
        }

        view.addSubview(completeView)
        view.pinSubviewToAllEdges(completeView)
    }

    @objc private func doneTapped() {
        self.dismiss(animated: true)
    }

}

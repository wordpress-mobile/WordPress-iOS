import UIKit
import WordPressUI

struct RestoreStatusFailedConfiguration {
    let title: String
    let messageTitle: String
    let firstHint: String
    let secondHint: String
    let thirdHint: String
}

class BaseRestoreStatusFailedViewController: UIViewController {

    private let configuration: RestoreStatusFailedConfiguration

    lazy var restoreStatusFailedView: RestoreStatusFailedView = {
        let restoreStatusFailedView = RestoreStatusFailedView.loadFromNib()
        restoreStatusFailedView.translatesAutoresizingMaskIntoConstraints = false
        return restoreStatusFailedView
    }()

    // MARK: - Init

    init() {
        fatalError("A configuration struct needs to be provided")
    }

    init(configuration: RestoreStatusFailedConfiguration) {
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
        configureRestoreStatusFailedView()
    }

    // MARK: - Private

    private func configureTitle() {
        title = configuration.title
    }

    private func configureNavigation() {
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                           target: self,
                                                           action: #selector(doneTapped))
    }

    private func configureRestoreStatusFailedView() {
        restoreStatusFailedView.configure(
            title: configuration.messageTitle,
            firstHint: configuration.firstHint,
            secondHint: configuration.secondHint,
            thirdHint: configuration.thirdHint
        )

        restoreStatusFailedView.doneButtonHandler = { [weak self] in
            self?.doneTapped()
        }

        view.addSubview(restoreStatusFailedView)
        view.pinSubviewToAllEdges(restoreStatusFailedView)
    }

    @objc private func doneTapped() {
        self.dismiss(animated: true)
    }
}

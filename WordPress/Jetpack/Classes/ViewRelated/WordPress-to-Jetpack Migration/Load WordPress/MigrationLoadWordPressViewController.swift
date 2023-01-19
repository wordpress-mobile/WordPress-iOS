import UIKit

class MigrationLoadWordPressViewController: UIViewController {

    // MARK: - Dependencies

    private let viewModel: MigrationLoadWordPressViewModel
    private let tracker: MigrationAnalyticsTracker

    // MARK: - Views

    private lazy var migrationView = MigrationStepView(
        headerView: MigrationHeaderView(configuration: viewModel.header),
        actionsView: MigrationActionsView(configuration: viewModel.actions),
        centerView: UIView()
    )

    // MARK: - Init

    init(viewModel: MigrationLoadWordPressViewModel, tracker: MigrationAnalyticsTracker = .init()) {
        self.viewModel = viewModel
        self.tracker = tracker
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func loadView() {
        self.view = self.migrationView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = MigrationAppearance.backgroundColor
        self.setupNavigationBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tracker.track(.loadWordPressScreenShown)
    }

    override func viewDidLayoutSubviews() {
        let isNavBarHidden = navigationController?.isNavigationBarHidden ?? true
        self.migrationView.additionalContentInset.top = isNavBarHidden ? MigrationStepView.Constants.topContentInset : 0
        super.viewDidLayoutSubviews()
    }

    // MARK: - Setup UI

    private func setupNavigationBar() {
        let closeButton = UIButton.makeCloseButton()
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        let item = UIBarButtonItem(customView: closeButton)
        self.navigationItem.rightBarButtonItem = item
    }

    // MARK: - User Interaction

    @objc private func closeButtonTapped() {
        self.tracker.track(.loadWordPressScreenNoThanksTapped)
        self.dismiss(animated: true)
    }
}

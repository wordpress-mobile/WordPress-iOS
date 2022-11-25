import UIKit

final class MigrationDeleteWordPressViewController: UIViewController {

    // MARK: - Dependencies

    private let viewModel: MigrationDeleteWordPressViewModel

    // MARK: - Init

    init(viewModel: MigrationDeleteWordPressViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    convenience init() {
        let actions = MigrationDeleteWordPressViewModel.Actions()
        self.init(viewModel: MigrationDeleteWordPressViewModel(actions: actions))
        actions.primary = { [weak self] in
            self?.primaryButtonTapped()
        }
        actions.secondary = { [weak self] in
            self?.secondaryButtonTapped()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func loadView() {
        let centerContentView = MigrationDoneCenterView()
        let centerView = MigrationCenterView(
            contentView: centerContentView,
            configuration: viewModel.content
        )
        let migrationView = MigrationStepView(
            headerView: MigrationHeaderView(configuration: viewModel.header),
            actionsView: MigrationActionsView(configuration: viewModel.actions),
            centerView: centerView
        )
        migrationView.additionalContentInset.top = 0
        self.view = migrationView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNavigationBar()
        self.setupDismissButton()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = MigrationAppearance.backgroundColor
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        if #available(iOS 15.0, *) {
            navigationItem.compactScrollEdgeAppearance = appearance
        }
    }

    private func setupDismissButton() {
        let closeButton = UIButton.makeCloseButton()
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        let item = UIBarButtonItem(customView: closeButton)
        self.navigationItem.rightBarButtonItem = item
    }

    // MARK: - User Interaction

    @objc private func closeButtonTapped() {
        self.dismiss(animated: true)
    }

    private func primaryButtonTapped() {
        self.dismiss(animated: true)
    }

    private func secondaryButtonTapped() {
        let destination = SupportTableViewController()
        self.present(UINavigationController(rootViewController: destination), animated: true)
    }
}


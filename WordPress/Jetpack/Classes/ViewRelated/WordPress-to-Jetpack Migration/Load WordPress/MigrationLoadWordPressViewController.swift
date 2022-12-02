import UIKit

class MigrationLoadWordPressViewController: UIViewController {

    // MARK: - Dependencies

    private let viewModel: MigrationLoadWordPressViewModel

    // MARK: - Init

    init(viewModel: MigrationLoadWordPressViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func loadView() {
        let migrationView = MigrationStepView(
            headerView: MigrationHeaderView(configuration: viewModel.header),
            actionsView: MigrationActionsView(configuration: viewModel.actions),
            centerView: UIView()
        )
        migrationView.additionalContentInset.top = 0
        self.view = migrationView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = MigrationAppearance.backgroundColor
    }
}

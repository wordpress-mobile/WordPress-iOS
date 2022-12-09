import UIKit

class MigrationLoadWordPressViewController: UIViewController {

    // MARK: - Dependencies

    private let viewModel: MigrationLoadWordPressViewModel
    private let tracker: MigrationAnalyticsTracker

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
        let migrationView = MigrationStepView(
            headerView: MigrationHeaderView(configuration: viewModel.header),
            actionsView: MigrationActionsView(configuration: viewModel.actions),
            centerView: UIView()
        )
        self.view = migrationView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = MigrationAppearance.backgroundColor
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tracker.track(.loadWordPressScreenShown)
    }
}

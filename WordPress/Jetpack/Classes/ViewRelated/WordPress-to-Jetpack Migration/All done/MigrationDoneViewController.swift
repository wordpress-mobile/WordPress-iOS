import UIKit

class MigrationDoneViewController: UIViewController {

    private let viewModel: MigrationDoneViewModel

    private let tracker: MigrationAnalyticsTracker

    init(viewModel: MigrationDoneViewModel, tracker: MigrationAnalyticsTracker = .init()) {
        self.viewModel = viewModel
        self.tracker = tracker
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = MigrationStepView(
            headerView: MigrationHeaderView(configuration: viewModel.configuration.headerConfiguration),
            actionsView: MigrationActionsView(configuration: viewModel.configuration.actionsConfiguration),
            centerView: MigrationCenterView.deleteWordPress(with: viewModel.configuration.centerViewConfiguration)
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tracker.track(.thanksScreenShown)
    }
}

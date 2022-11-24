import UIKit

class MigrationNotificationsViewController: UIViewController {

    private let viewModel: MigrationNotificationsViewModel

    init(viewModel: MigrationNotificationsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let centerContentView = MigrationNotificationsCenterView()
        let centerView = MigrationCenterView(contentView: centerContentView,
                                             configuration: viewModel.configuration.centerViewConfiguration)

        view = MigrationStepView(headerView: MigrationHeaderView(configuration: viewModel.configuration.headerConfiguration),
                                 actionsView: MigrationActionsView(configuration: viewModel.configuration.actionsConfiguration),
                                 centerView: centerView)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

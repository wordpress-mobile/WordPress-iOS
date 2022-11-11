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

        view = MigrationStepView(headerView: MigrationHeaderView(configuration: viewModel.configuration.headerConfiguration),
                                 actionsView: MigrationActionsView(configuration: viewModel.configuration.actionsConfiguration),
                                 centerView: MigrationCenterView(contentView: MigrationNotificationsCenterView()))
    }
}

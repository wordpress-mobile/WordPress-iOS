import UIKit

class MigrationDoneViewController: UIViewController {

    private let viewModel: MigrationDoneViewModel

    init(viewModel: MigrationDoneViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        // TODO: replace this blank center view with the actual content
        let centerView = UIView()
        centerView.translatesAutoresizingMaskIntoConstraints = false
        centerView.setContentHuggingPriority(UILayoutPriority.defaultLow, for: .vertical)

        view = MigrationStepView(headerView: MigrationHeaderView(configuration: viewModel.configuration.headerConfiguration),
                                 actionsView: MigrationActionsView(configuration: viewModel.configuration.actionsConfiguration),
                                 centerView: centerView)
    }
}

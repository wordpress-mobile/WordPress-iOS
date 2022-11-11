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
        let centerContentView = MigrationDoneCenterView()
        let centerView = MigrationCenterView(contentView: centerContentView,
                                             descriptionText: TextContent.description,
                                             highlightedDescriptionText: TextContent.highlightedDescription)

        view = MigrationStepView(headerView: MigrationHeaderView(configuration: viewModel.configuration.headerConfiguration),
                                 actionsView: MigrationActionsView(configuration: viewModel.configuration.actionsConfiguration),
                                 centerView: centerView)
    }

    enum TextContent {

        static let description = NSLocalizedString("migration.done.footer",
                                                   value: "Please delete the WordPress app to avoid data conflicts.",
                                                   comment: "Footer for the migration done screen.")
        static let highlightedDescription = NSLocalizedString("migration.done.footer.highlighted",
                                                       value: "delete the WordPress app",
                                                       comment: "Highlighted text in the footer of the migration done screen.")
    }
}

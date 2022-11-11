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
                                             descriptionText: TextContent.description,
                                             highlightedDescriptionText: TextContent.highlightedDescription)

        view = MigrationStepView(headerView: MigrationHeaderView(configuration: viewModel.configuration.headerConfiguration),
                                 actionsView: MigrationActionsView(configuration: viewModel.configuration.actionsConfiguration),
                                 centerView: centerView)
    }

    enum TextContent {

        static let description = NSLocalizedString("migration.notifications.footer",
                                                   value: "When the alert apears tap Allow to continue receiving all your WordPress notifications.",
                                                   comment: "Footer for the migration notifications screen.")
        static let highlightedDescription = NSLocalizedString("migration.notifications.footer.highlighted",
                                                       value: "Allow",
                                                       comment: "Highlighted text in the footer of the migration notifications screen.")
    }
}

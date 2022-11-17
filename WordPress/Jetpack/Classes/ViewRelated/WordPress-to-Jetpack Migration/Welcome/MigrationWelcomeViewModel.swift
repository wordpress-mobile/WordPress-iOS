import UIKit

final class MigrationWelcomeViewModel {

    // MARK: - Properties

    var gravatarEmail: String?

    let blogListDataSource: BlogListDataSource

    let configuration: MigrationStepConfiguration

    // MARK: - Init

    init(account: WPAccount?, coordinator: MigrationFlowCoordinator) {
        if let account {
            self.gravatarEmail = account.email
        }

        self.blogListDataSource = BlogListDataSource()
        self.blogListDataSource.loggedIn = true
        self.blogListDataSource.account = account

        let headerConfiguration = MigrationHeaderConfiguration(step: .welcome,
                                                               multiSite: blogListDataSource.visibleBlogsCount > 1)

        let primaryHandler = { [weak coordinator] () -> Void in
            coordinator?.transitionToNextStep()
        }
        let secondaryHandler = { [weak coordinator] () -> Void in
            // Which object is responsible for displaying the support screen?
            //
            // The following code needs to be executed somewhere:
            //
            // let destination = SupportTableViewController()
            // presentingViewController.present(destination, completion: nil)
            //
            // Approaches considered:
            //
            // 1. The View Model shouldn't be responsible for displaying the support screen
            // 2. The coordination can't perform the presentation because it doesn't have access to the `presenting` view controller
            // 3. I thought of making the `MigrationViewControllerFactory` responsible for creating the `secondaryHandler` and injecting it into this view model
            //    But that didn't work as well.
            //
            // Workaround:
            //
            coordinator?.routeToSupportViewController?()
        }
        let actionsConfiguration = MigrationActionsViewConfiguration(step: .welcome, primaryHandler: primaryHandler, secondaryHandler: secondaryHandler)
        configuration = MigrationStepConfiguration(headerConfiguration: headerConfiguration,
                                                   centerViewConfiguration: nil,
                                                   actionsConfiguration: actionsConfiguration)
    }
}

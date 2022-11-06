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

        configuration = MigrationStepConfiguration(headerConfiguration:
                                                    MigrationHeaderConfiguration(step: .welcome,
                                                                                 multiSite: blogListDataSource.visibleBlogsCount > 1),
                                                   actionsConfiguration:
                                                    MigrationActionsViewConfiguration(step: .welcome,
                                                                                      primaryHandler: { [weak coordinator] in
            coordinator?.transitionToNextStep()
        },
                                                                                      secondaryHandler: {

        }))

    }
}

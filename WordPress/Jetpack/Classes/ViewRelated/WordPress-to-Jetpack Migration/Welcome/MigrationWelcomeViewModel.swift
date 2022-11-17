import UIKit

final class MigrationWelcomeViewModel {

    // MARK: - Properties

    let gravatarEmail: String?
    let configuration: MigrationStepConfiguration
    let blogListDataSource: BlogListDataSource

    // MARK: - Init

    init(gravatarEmail: String?, blogListDataSource: BlogListDataSource, configuration: MigrationStepConfiguration) {
        self.gravatarEmail = gravatarEmail
        self.configuration = configuration
        self.blogListDataSource = blogListDataSource
    }

    convenience init(account: WPAccount?, actions: MigrationActionsViewConfiguration) {
        let blogsDataSource = BlogListDataSource()
        blogsDataSource.loggedIn = true
        blogsDataSource.account = account
        let header = MigrationHeaderConfiguration(
            step: .welcome,
            multiSite: blogsDataSource.visibleBlogsCount > 1
        )
        let configuration = MigrationStepConfiguration(
            headerConfiguration: header,
            centerViewConfiguration: nil,
            actionsConfiguration: actions
        )
        self.init(
            gravatarEmail: account?.email,
            blogListDataSource: blogsDataSource,
            configuration: configuration
        )
    }
}

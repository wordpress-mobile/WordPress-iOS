import UIKit

final class MigrationWelcomeViewModel {

    // MARK: - Properties

    let gravatarEmail: String?
    let configuration: MigrationStepConfiguration
    let sites: [BlogListSiteViewModel]

    // MARK: - Init

    init(account: WPAccount?, actions: MigrationActionsViewConfiguration) {
        self.gravatarEmail = account?.email
        self.sites = ((try? BlogQuery().blogs(in: ContextManager.shared.mainContext)) ?? [])
            .map(BlogListSiteViewModel.init)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        let header = MigrationHeaderConfiguration(
            step: .welcome,
            multiSite: sites.count > 1
        )
        self.configuration = MigrationStepConfiguration(
            headerConfiguration: header,
            centerViewConfiguration: nil,
            actionsConfiguration: actions
        )
    }
}

import Foundation
import WordPressData

final class MigrationWelcomeViewModel {

    // MARK: - Properties

    let configuration: MigrationStepConfiguration
    let sites: [BlogListSiteViewModel]

    // MARK: - Init

    init(actions: MigrationActionsViewConfiguration) {
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

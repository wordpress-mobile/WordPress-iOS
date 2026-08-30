import AppIntents
import JetpackStatsWidgetsCore
import WordPressData

/// Opens Stats for a chosen site, or the last used site when none is picked.
struct OpenStatsIntent: AppIntent {
    static let title = LocalizedStringResource(
        "ios-appintents.openStats.title",
        defaultValue: "Open Stats",
        table: "AppIntents",
        comment: "Title of the App Intent that opens Stats for a site. Shown in the Shortcuts app and Spotlight."
    )
    static let description = IntentDescription(
        LocalizedStringResource(
            "ios-appintents.openStats.description",
            defaultValue: "Opens the stats for one of your sites.",
            table: "AppIntents",
            comment: "Description of the App Intent that opens Stats for a site. Shown in the Shortcuts app."
        )
    )
    static let openAppWhenRun = true

    @Parameter(
        title: LocalizedStringResource(
            "ios-widget.ILcGmf",
            defaultValue: "Site",
            table: "Localizable",
            comment: "Label of the site parameter of the Open Stats App Intent. Shown in the Shortcuts app."
        )
    )
    var site: SiteEntity?

    @MainActor
    func perform() async throws -> some IntentResult {
        guard AccountHelper.isLoggedIn else {
            throw AppIntentOpenError.notLoggedIn
        }
        guard let blog = Blog.forAppIntent(siteIdentifier: site?.id, in: ContextManager.shared.mainContext) else {
            throw AppIntentOpenError.siteNotFound
        }
        let presenter = RootViewCoordinator.sharedPresenter
        presenter.rootViewController.dismiss(animated: false)
        presenter.showStats(for: blog, source: .shortcut)
        return .result()
    }
}

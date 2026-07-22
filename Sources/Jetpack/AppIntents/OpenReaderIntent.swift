import AppIntents

/// Opens the Reader tab.
struct OpenReaderIntent: AppIntent {
    static let title = LocalizedStringResource(
        "notifications.emptyState.buttonOpenReader",
        defaultValue: "Open Reader",
        table: "Localizable",
        comment: "Title of the App Intent that opens the Reader tab. Shown in the Shortcuts app and Spotlight."
    )
    static let description = IntentDescription(
        LocalizedStringResource(
            "ios-appintents.openReader.description",
            defaultValue: "Opens the Reader to browse blogs you follow.",
            table: "AppIntents",
            comment: "Description of the App Intent that opens the Reader tab. Shown in the Shortcuts app."
        )
    )
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        guard AccountHelper.isLoggedIn else {
            throw AppIntentOpenError.notLoggedIn
        }
        let presenter = RootViewCoordinator.sharedPresenter
        presenter.rootViewController.dismiss(animated: false)
        presenter.showReader(path: nil)
        return .result()
    }
}

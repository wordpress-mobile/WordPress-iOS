import AppIntents

/// Opens the Notifications tab.
struct OpenNotificationsIntent: AppIntent {
    static let title = LocalizedStringResource(
        "ios-appintents.openNotifications.title",
        defaultValue: "Open Notifications",
        table: "AppIntents",
        comment: "Title of the App Intent that opens the Notifications tab. Shown in the Shortcuts app and Spotlight."
    )
    static let description = IntentDescription(
        LocalizedStringResource(
            "ios-appintents.openNotifications.description",
            defaultValue: "Opens your notifications.",
            table: "AppIntents",
            comment: "Description of the App Intent that opens the Notifications tab. Shown in the Shortcuts app."
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
        presenter.showNotificationsTab()
        return .result()
    }
}

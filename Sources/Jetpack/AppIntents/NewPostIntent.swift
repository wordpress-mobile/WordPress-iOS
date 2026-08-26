import AppIntents

/// Opens the post editor for the last used site.
struct NewPostIntent: AppIntent {
    static let title = LocalizedStringResource(
        "New Post",
        defaultValue: "New Post",
        table: "Localizable",
        comment: "Title of the App Intent that opens the post editor. Shown in the Shortcuts app and Spotlight."
    )
    static let description = IntentDescription(
        LocalizedStringResource(
            "ios-appintents.newPost.description",
            defaultValue: "Opens the editor to write a new post.",
            table: "AppIntents",
            comment: "Description of the App Intent that opens the post editor. Shown in the Shortcuts app."
        )
    )
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        guard AccountHelper.isLoggedIn else {
            throw AppIntentOpenError.notLoggedIn
        }
        RootViewCoordinator.sharedPresenter.showNewPostEditor(
            context: NewPostEditorContext(
                analytics: .editorCreatedPost(source: "create_button", postType: "post"),
                animated: false
            )
        )
        return .result()
    }
}

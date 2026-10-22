import AppIntents
import Foundation

/// Opens a post or page in the app, with the same routing as tapping it in Spotlight.
struct OpenPostIntent: AppIntent {
    static let title = LocalizedStringResource(
        "ios-appintents.openPost.title",
        defaultValue: "Open Post",
        table: "AppIntents",
        comment:
            "Title of the App Intent that opens one of the user's posts or pages. Shown in the Shortcuts app and Spotlight."
    )
    static let description = IntentDescription(
        LocalizedStringResource(
            "ios-appintents.openPost.description",
            defaultValue: "Opens one of your posts or pages in the app.",
            table: "AppIntents",
            comment:
                "Description of the App Intent that opens one of the user's posts or pages. Shown in the Shortcuts app."
        )
    )
    static let openAppWhenRun = true

    @Parameter(
        title: LocalizedStringResource(
            "ios-appintents.openPost.postParameter",
            defaultValue: "Post",
            table: "AppIntents",
            comment: "Label of the post parameter of the Open Post App Intent. Shown in the Shortcuts app."
        )
    )
    var post: PostEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        try await SearchManager.shared.openForAppIntent(withUniqueIdentifier: post.id)
        return .result()
    }
}

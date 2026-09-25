import AppIntents
import Foundation

/// Opens a Reader post in the app, with the same routing as tapping it in Spotlight.
struct OpenReaderPostIntent: AppIntent {
    static let title = LocalizedStringResource(
        "ios-appintents.openReaderPost.title",
        defaultValue: "Open Reader Post",
        table: "AppIntents",
        comment: "Title of the App Intent that opens a Reader post. Shown in the Shortcuts app and Spotlight."
    )
    static let description = IntentDescription(
        LocalizedStringResource(
            "ios-appintents.openReaderPost.description",
            defaultValue: "Opens a post from your Reader in the app.",
            table: "AppIntents",
            comment: "Description of the App Intent that opens a Reader post. Shown in the Shortcuts app."
        )
    )
    static let openAppWhenRun = true

    @Parameter(
        title: LocalizedStringResource(
            "ios-appintents.openReaderPost.postParameter",
            defaultValue: "Post",
            table: "AppIntents",
            comment: "Label of the post parameter of the Open Reader Post App Intent. Shown in the Shortcuts app."
        )
    )
    var post: ReaderPostEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        try await SearchManager.shared.openForAppIntent(withUniqueIdentifier: post.id)
        return .result()
    }
}

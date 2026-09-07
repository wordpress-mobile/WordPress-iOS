import AppIntents
import Foundation
import WordPressData

/// Publishes a draft, pending, or scheduled post after the user confirms.
struct PublishPostIntent: AppIntent {
    static let title = LocalizedStringResource(
        "ios-appintents.publishPost.title",
        defaultValue: "Publish Post",
        table: "AppIntents",
        comment: "Title of the App Intent that publishes a post. Shown in the Shortcuts app and Spotlight."
    )
    static let description = IntentDescription(
        LocalizedStringResource(
            "ios-appintents.publishPost.description",
            defaultValue: "Publishes one of your draft, pending, or scheduled posts.",
            table: "AppIntents",
            comment: "Description of the App Intent that publishes a post. Shown in the Shortcuts app."
        )
    )

    @Parameter(
        title: LocalizedStringResource(
            "ios-appintents.publishPost.postParameter",
            defaultValue: "Post",
            table: "AppIntents",
            comment: "Label of the post parameter of the Publish Post App Intent. Shown in the Shortcuts app."
        ),
        optionsProvider: PublishablePostOptionsProvider()
    )
    var post: PostEntity

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<PostEntity> {
        let context = ContextManager.shared.mainContext
        guard let target = AbstractPost.forAppIntent(identifier: post.id, in: context) else {
            throw AppIntentPublishError.postNotFound
        }
        if let blocker = target.appIntentPublishingBlocker {
            throw AppIntentPublishError(blocker)
        }

        let title = target.titleForDisplay()
        // TODO: migrate to requestConfirmation(conditions:actionName:dialog:) once the deployment target reaches iOS 18.
        try await requestConfirmation(
            result: .result(
                dialog: IntentDialog(
                    LocalizedStringResource(
                        "ios-appintents.publishPost.confirmationDialog",
                        defaultValue: "Publish “\(title)”?",
                        table: "AppIntents",
                        comment:
                            "Confirmation dialog shown by Siri or the Shortcuts app before publishing. %1$@ is the post title."
                    )
                )
            ),
            confirmationActionName: .post
        )
        // The post can change while the confirmation dialog is up (e.g. the
        // editor creates an unsaved revision); re-check before acting.
        if let blocker = target.appIntentPublishingBlocker {
            throw AppIntentPublishError(blocker)
        }

        try await AppIntentPostSaving.save(target, changes: target.appIntentPublishParameters())

        guard let updated = PostEntity(post: target) else {
            throw AppIntentPublishError.postNotFound
        }
        // A post with a future publish date comes back scheduled rather than
        // published; the dialog reflects what the server actually did.
        let dialog: IntentDialog
        if target.status == .scheduled, let date = target.dateCreated {
            dialog = IntentDialog(
                LocalizedStringResource(
                    "ios-appintents.publishPost.scheduledDialog",
                    defaultValue: "Scheduled “\(title)” for \(date.formatted(date: .abbreviated, time: .shortened)).",
                    table: "AppIntents",
                    comment:
                        "Dialog shown by Siri or the Shortcuts app when publishing a post scheduled it instead because its publish date is in the future. %1$@ is the post title, %2$@ the formatted publish date."
                )
            )
        } else {
            dialog = IntentDialog(
                LocalizedStringResource(
                    "ios-appintents.publishPost.publishedDialog",
                    defaultValue: "Published “\(title)”.",
                    table: "AppIntents",
                    comment:
                        "Dialog shown by Siri or the Shortcuts app after a post was published. %1$@ is the post title."
                )
            )
        }
        return .result(value: updated, dialog: dialog)
    }
}

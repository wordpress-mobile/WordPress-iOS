import AppIntents
import Foundation
import WordPressData

/// Schedules a draft, pending, or already-scheduled post for a future date
/// after the user confirms.
struct SchedulePostIntent: AppIntent {
    static let title = LocalizedStringResource(
        "ios-appintents.schedulePost.title",
        defaultValue: "Schedule Post",
        table: "AppIntents",
        comment: "Title of the App Intent that schedules a post. Shown in the Shortcuts app and Spotlight."
    )
    static let description = IntentDescription(
        LocalizedStringResource(
            "ios-appintents.schedulePost.description",
            defaultValue: "Schedules one of your draft, pending, or scheduled posts to publish at a future date.",
            table: "AppIntents",
            comment: "Description of the App Intent that schedules a post. Shown in the Shortcuts app."
        )
    )

    @Parameter(
        title: LocalizedStringResource(
            "ios-appintents.schedulePost.postParameter",
            defaultValue: "Post",
            table: "AppIntents",
            comment: "Label of the post parameter of the Schedule Post App Intent. Shown in the Shortcuts app."
        ),
        optionsProvider: PublishablePostOptionsProvider()
    )
    var post: PostEntity

    @Parameter(
        title: LocalizedStringResource(
            "publishDatePicker.title",
            defaultValue: "Publish Date",
            table: "Localizable",
            comment: "Label of the date parameter of the Schedule Post App Intent. Shown in the Shortcuts app."
        )
    )
    var date: Date

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<PostEntity> {
        let context = ContextManager.shared.mainContext
        guard let target = AbstractPost.forAppIntent(identifier: post.id, in: context) else {
            throw AppIntentPublishError.postNotFound
        }
        if let blocker = target.appIntentPublishingBlocker {
            throw AppIntentPublishError(blocker)
        }
        guard date > .now else {
            throw AppIntentPublishError.dateMustBeInFuture
        }

        let title = target.titleForDisplay()
        let formattedDate = date.formatted(date: .abbreviated, time: .shortened)
        // TODO: migrate to requestConfirmation(conditions:actionName:dialog:) once the deployment target reaches iOS 18.
        try await requestConfirmation(
            result: .result(
                dialog: IntentDialog(
                    LocalizedStringResource(
                        "ios-appintents.schedulePost.confirmationDialog",
                        defaultValue: "Schedule “\(title)” for \(formattedDate)?",
                        table: "AppIntents",
                        comment:
                            "Confirmation dialog shown by Siri or the Shortcuts app before scheduling. %1$@ is the post title, %2$@ the formatted publish date."
                    )
                )
            ),
            confirmationActionName: .set
        )
        // The post can change and the chosen date can lapse while the
        // confirmation dialog is up; re-check both before acting.
        if let blocker = target.appIntentPublishingBlocker {
            throw AppIntentPublishError(blocker)
        }
        guard date > .now else {
            throw AppIntentPublishError.dateMustBeInFuture
        }

        try await AppIntentPostSaving.save(target, changes: target.appIntentScheduleParameters(for: date))

        guard let updated = PostEntity(post: target) else {
            throw AppIntentPublishError.postNotFound
        }
        // The server publishes immediately when the date is no longer far
        // enough in the future; the dialog reflects what it actually did.
        let dialog: IntentDialog
        if target.status == .publish {
            dialog = IntentDialog(
                LocalizedStringResource(
                    "ios-appintents.schedulePost.publishedDialog",
                    defaultValue: "Published “\(title)”.",
                    table: "AppIntents",
                    comment:
                        "Dialog shown by Siri or the Shortcuts app when scheduling published the post immediately because its date was no longer in the future. %1$@ is the post title."
                )
            )
        } else {
            let scheduledDate = (target.dateCreated ?? date).formatted(date: .abbreviated, time: .shortened)
            dialog = IntentDialog(
                LocalizedStringResource(
                    "ios-appintents.schedulePost.scheduledDialog",
                    defaultValue: "Scheduled “\(title)” for \(scheduledDate).",
                    table: "AppIntents",
                    comment:
                        "Dialog shown by Siri or the Shortcuts app after a post was scheduled. %1$@ is the post title, %2$@ the formatted publish date."
                )
            )
        }
        return .result(value: updated, dialog: dialog)
    }
}

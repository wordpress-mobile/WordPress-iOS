import AppIntents
import Foundation
import WordPressData

/// Errors surfaced to the system when a publish or schedule intent cannot act.
enum AppIntentPublishError: Error, CustomLocalizedStringResourceConvertible {
    case postNotFound
    case isPage
    case hasUnsavedChanges
    case notPublishable
    case publishingNotAllowed
    case dateMustBeInFuture

    /// The save was rejected; `reason` carries the server's own message
    /// (e.g. the `rest_cannot_publish` explanation) rather than a generic
    /// failure string.
    case saveFailed(reason: String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .postNotFound:
            return LocalizedStringResource(
                "ios-appintents.publishError.postNotFound",
                defaultValue: "The post could not be found.",
                table: "AppIntents",
                comment:
                    "Error shown by Siri or the Shortcuts app when the post a publish or schedule App Intent should act on no longer exists."
            )
        case .isPage:
            return LocalizedStringResource(
                "ios-appintents.publishError.isPage",
                defaultValue: "Publishing pages is not supported.",
                table: "AppIntents",
                comment:
                    "Error shown by Siri or the Shortcuts app when the selected item is a page, which publish App Intents do not support."
            )
        case .hasUnsavedChanges:
            return LocalizedStringResource(
                "ios-appintents.publishError.hasUnsavedChanges",
                defaultValue: "The post has unsaved changes. Open it in the app to publish it.",
                table: "AppIntents",
                comment:
                    "Error shown by Siri or the Shortcuts app when the post has local changes that must be resolved in the app before publishing."
            )
        case .notPublishable:
            return LocalizedStringResource(
                "ios-appintents.publishError.notPublishable",
                defaultValue: "The post is already published or cannot be published.",
                table: "AppIntents",
                comment: "Error shown by Siri or the Shortcuts app when the post is not in a publishable state."
            )
        case .publishingNotAllowed:
            return LocalizedStringResource(
                "ios-appintents.publishError.publishingNotAllowed",
                defaultValue: "You don't have permission to publish posts on this site.",
                table: "AppIntents",
                comment:
                    "Error shown by Siri or the Shortcuts app when the signed-in user lacks the capability to publish posts on the site."
            )
        case .dateMustBeInFuture:
            return LocalizedStringResource(
                "ios-appintents.publishError.dateMustBeInFuture",
                defaultValue: "The publish date must be in the future.",
                table: "AppIntents",
                comment: "Error shown by Siri or the Shortcuts app when the chosen schedule date is not in the future."
            )
        case .saveFailed(let reason):
            return "\(reason)"
        }
    }
}

extension AppIntentPublishError {
    init(_ blocker: AbstractPost.AppIntentPublishingBlocker) {
        switch blocker {
        case .isPage:
            self = .isPage
        case .hasUnsavedChanges:
            self = .hasUnsavedChanges
        case .localOnly, .notPublishable:
            self = .notPublishable
        case .publishingNotAllowed:
            self = .publishingNotAllowed
        }
    }
}

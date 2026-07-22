import Foundation
import WordPressData
import WordPressKit

/// Saves a post status change on behalf of an App Intent.
///
/// Mirrors the `PostCoordinator.save` orchestration (sync pausing, error
/// analytics, deleted-post cleanup, and the post-publish side effects)
/// except for its UIKit pieces, which would present alerts and notices on
/// top of the intent's own dialogs.
enum AppIntentPostSaving {
    @MainActor
    static func save(_ post: AbstractPost, changes: RemotePostUpdateParameters) async throws {
        let coordinator = PostCoordinator.shared
        await coordinator.pauseSyncing(for: post)
        defer { coordinator.resumeSyncing(for: post) }

        let previousStatus = post.status
        do {
            try await PostRepository().save(post, changes: changes)
        } catch {
            // Same operation string as PostCoordinator.save: the failure
            // surface is the same call, and analytics funnel on it.
            coordinator.trackError(error, operation: "post-save", post: post)
            // A post deleted on the server can never be saved again; drop
            // the local copy (as the in-app flow does) so the intents stop
            // offering it. The error message carries the post title.
            if let saveError = error as? PostRepository.PostSaveError, case .deleted = saveError {
                coordinator.handlePermanentlyDeleted(post)
            }
            // For WP.com endpoint errors the localized description is the
            // server's own message (e.g. why publishing was rejected).
            throw AppIntentPublishError.saveFailed(reason: error.localizedDescription)
        }
        coordinator.didPublish(post, previousStatus: previousStatus)
        // Unconditional on purpose: re-scheduling an already-scheduled post
        // does not pass didPublish's status-changed gate but must still
        // refresh the Spotlight entry; the repeated upsert is idempotent.
        SearchManager.shared.indexItem(post)
    }
}

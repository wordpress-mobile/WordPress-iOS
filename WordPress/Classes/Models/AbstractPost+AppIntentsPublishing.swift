import Foundation
import WordPressData
import WordPressKit

extension AbstractPost {
    /// Why an App Intent cannot publish or schedule the post.
    enum AppIntentPublishingBlocker {
        case isPage
        case localOnly
        case hasUnsavedChanges
        case notPublishable
        case publishingNotAllowed
    }

    /// The statuses an App Intent can publish or schedule a post from, shared
    /// between the eligibility check and the picker fetch so they cannot
    /// drift apart.
    static let appIntentPublishableStatuses: [Status] = [.draft, .pending, .scheduled]

    /// Returns the reason an App Intent must refuse to publish or schedule
    /// this post, or `nil` when it can proceed.
    ///
    /// Posts with unsaved local edits are refused rather than synced: an
    /// intent publishing half-finished editor changes is never what the
    /// user asked for.
    var appIntentPublishingBlocker: AppIntentPublishingBlocker? {
        if self is Page {
            return .isPage
        }
        guard hasRemote() else {
            return .localOnly
        }
        if hasRevision() {
            return .hasUnsavedChanges
        }
        guard let status, Self.appIntentPublishableStatuses.contains(status) else {
            return .notPublishable
        }
        // Sites without loaded capabilities (self-hosted) stay allowed, the
        // same trade-off the in-app publish affordances make.
        if blog.capabilities != nil && !blog.isPublishingPostsAllowed() {
            return .publishingNotAllowed
        }
        return nil
    }

    /// The delta that publishes the post immediately.
    func appIntentPublishParameters(now: Date = .now) -> RemotePostUpdateParameters {
        var changes = RemotePostUpdateParameters()
        changes.status = Post.Status.publish.rawValue
        changes.setDateForImmediatePublishIfNeeded(previousStatus: status, now: now)
        return changes
    }

    /// The delta that schedules the post for the given date.
    func appIntentScheduleParameters(for date: Date) -> RemotePostUpdateParameters {
        var changes = RemotePostUpdateParameters()
        changes.status = Post.Status.scheduled.rawValue
        changes.date = date
        return changes
    }
}

extension Post {
    /// Returns the most recently modified posts an App Intent can offer for
    /// publishing or scheduling. Only server-synced originals in a
    /// publishable status with no unsaved local edits qualify; see
    /// `appIntentPublishingBlocker` for why the rest are excluded.
    ///
    /// The result is capped: `DynamicOptionsProvider` has no search hook on
    /// iOS 17, so this feeds a fixed picker of recents rather than a
    /// searchable index.
    static func recentForAppIntentPublishing(
        limit: Int = 20,
        in context: NSManagedObjectContext
    ) -> [Post] {
        let statuses = appIntentPublishableStatuses.map(\.rawValue)
        let request = NSFetchRequest<Post>(entityName: Post.entityName())
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "original = NULL AND revision = NULL AND postID > 0"),
            NSPredicate(format: "status IN %@", statuses)
        ])
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(AbstractPost.dateModified), ascending: false)]
        request.fetchLimit = limit
        return (try? context.fetch(request)) ?? []
    }
}

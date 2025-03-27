import Foundation
import WordPressKit
import WordPressShared

public extension AbstractPost {
    /// Returns the original post by navigating the entire list of revisions
    /// until it reaches the head.
    func original() -> AbstractPost {
        original?.original() ?? self
    }

    /// Returns `true` if the post was never uploaded to the remote and has
    /// not revisions that were marked for syncing.
    var isNewDraft: Bool {
        wpAssert(isOriginal(), "Must be called on the original")
        return !hasRemote() && getLatestRevisionNeedingSync() == nil
    }

    var isUnsavedRevision: Bool {
        isRevision() && !isSyncNeeded
    }

    /// Returns `true` if the post object is a revision created by one of the
    /// versions of the app prior to 24.7.
    var isLegacyUnsavedRevision: Bool {
        isRevision() && AbstractPost.deprecatedStatuses.contains(remoteStatus)
    }

    private static let deprecatedStatuses: Set<AbstractPostRemoteStatus> = [.pushing, .failed, .local, .sync, .pushingMedia, .autoSaved]

    // MARK: - Status

    /// Returns `true` is the post has one of the given statuses.
    func isStatus(in statuses: Set<Status>) -> Bool {
        statuses.contains(status ?? .draft)
    }

    @objc
    var remoteStatus: AbstractPostRemoteStatus {
        get {
            guard let remoteStatusNumber = remoteStatusNumber?.uintValue,
                  let status = AbstractPostRemoteStatus(rawValue: remoteStatusNumber) else {
                return .pushing
            }

            return status
        }

        set {
            remoteStatusNumber = NSNumber(value: newValue.rawValue)
        }
    }

    static func title(for status: Status) -> String {
        return title(forStatus: status.rawValue)
    }

    /// Returns the localized title for the specified status.  Status should be
    /// one of the `PostStatus...` constants.  If a matching title is not found
    /// the status is returned.
    ///
    /// - parameter status: The post status value
    ///
    /// - returns: The localized title for the specified status, or the status if a title was not found.
    ///
    @objc
    static func title(forStatus status: String) -> String {
        switch status {
        case PostStatusDraft:
            return NSLocalizedString("Draft", comment: "Name for the status of a draft post.")
        case PostStatusPending:
            return NSLocalizedString("Pending review", comment: "Name for the status of a post pending review.")
        case PostStatusPrivate:
            return NSLocalizedString("Private", comment: "Name for the status of a post that is marked private.")
        case PostStatusPublish:
            return NSLocalizedString("Published", comment: "Name for the status of a published post.")
        case PostStatusTrash:
            return NSLocalizedString("Trashed", comment: "Name for the status of a trashed post")
        case PostStatusScheduled:
            return NSLocalizedString("Scheduled", comment: "Name for the status of a scheduled post")
        default:
            return status
        }
    }

    var localizedPostType: String {
        switch self {
        case is Page:
            return NSLocalizedString("postType.page", value: "page", comment: "Localized post type: `Page`")
        default:
            return NSLocalizedString("postType.post", value: "post", comment: "Localized post type: `Post`")
        }
    }

    // MARK: - Misc

    /// A title describing the status. Ie.: "Public" or "Private" or "Password protected"
    @objc var titleForVisibility: String {
        PostVisibility(post: self).localizedTitle
    }

    /// Represent the supported properties used to sort posts.
    ///
    enum SortField {
        case dateCreated
        case dateModified

        /// The keyPath to access the underlying property.
        ///
        public var keyPath: String {
            switch self {
            case .dateCreated:
                return #keyPath(AbstractPost.date_created_gmt)
            case .dateModified:
                return #keyPath(AbstractPost.dateModified)
            }
        }
    }

    @objc func containsGutenbergBlocks() -> Bool {
        return content?.contains("<!-- wp:") ?? false
    }

    var analyticsUserInfo: [String: Any] {
        [
            "post_type": analyticsPostType ?? "",
            "status": status?.rawValue ?? "",
            "original_status": original().status?.rawValue ?? "unknown",
            "password_protected": PostVisibility(post: self) == .protected
        ]
    }

    var analyticsPostType: String? {
        switch self {
        case is Post:
            return "post"
        case is Page:
            return "page"
        default:
            return nil
        }
    }

    @objc override func featuredImageURLForDisplay() -> URL? {
        return featuredImageURL
    }

    /// Returns true if the post has any media that needs manual intervention to be uploaded
    ///
    func hasPermanentFailedMedia() -> Bool {
        return media.first(where: { !$0.willAttemptToUploadLater() }) != nil
    }

    /// Returns the changes made in the current revision compared to the
    /// previous revision or the original post if there is only one revision.
    var changes: RemotePostUpdateParameters {
        guard let original else {
            return RemotePostUpdateParameters() // Empty
        }
        return RemotePostUpdateParameters.changes(from: original, to: self)
    }

    /// Returns all revisions of the post including the original one.
    var allRevisions: [AbstractPost] {
        var revisions: [AbstractPost] = [self]
        var current = self
        while let next = current.revision {
            revisions.append(next)
            current = next
        }
        return revisions
    }

    @objc var isSyncNeeded: Bool {
        remoteStatus == .syncNeeded
    }

    /// Returns the latest saved revisions that needs to be synced with the server.
    /// Returns `nil` if there are no such revisions.
    func getLatestRevisionNeedingSync() -> AbstractPost? {
        wpAssert(original == nil, "Must be called on an original revision")
        let revision = allRevisions.last(where: \.isSyncNeeded)
        guard revision != self else {
            return nil
        }
        return revision
    }

    /// Deletes all of the synced revisions until and including the `latest`
    /// one passed as a parameter.
    func deleteSyncedRevisions(until latest: AbstractPost) {
        wpAssert(original == nil, "Must be called on an original revision")
        let tail = latest.revision

        var current = self
        while current !== latest, let next = current.revision {
            current.deleteRevision()
            current = next
        }

        if let tail {
            willChangeValue(forKey: "revision")
            setPrimitiveValue(tail, forKey: "revision")
            didChangeValue(forKey: "revision")
        }
    }

    /// Deletes the given revision and deletes the post if it's empty.
    static func deleteLatestRevision(_ revision: AbstractPost, in context: NSManagedObjectContext) {
        wpAssert(revision.isRevision() && !revision.isSyncNeeded, "must be a local revision")

        // - warning: The use of `.original` is intentional – we want to get
        // the previous revision in the list.
        guard let previous = revision.original else {
            return wpAssertionFailure("missing original")
        }
        let original = revision.original()
        previous.deleteRevision()
        if previous == original, !previous.hasRemote() {
            context.delete(original)
        }
    }

    func deleteAllRevisions() {
        wpAssert(isOriginal())
        for revision in allRevisions {
            revision.deleteRevision()
        }
    }
}

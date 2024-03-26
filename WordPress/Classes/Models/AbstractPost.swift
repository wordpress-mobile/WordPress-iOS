import Foundation

extension AbstractPost {

    func original() -> AbstractPost {
        original?.original() ?? self
    }

    var isNewDraft: Bool {
        assert(isOriginal(), "Must be called on the original")
        return !hasRemote() && getLatestRevisionNeedingSync() == nil
    }

    // MARK: - Status

    @objc
    var statusTitle: String? {
        guard let status = self.status else {
            return nil
        }

        return AbstractPost.title(for: status)
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

    /// The status of self when we last received its data from the API.
    ///
    /// This is mainly used to identify which Post List tab should the post be shown in. For
    /// example, if a published post is transitioned to a draft but the app has not finished
    /// updating the server yet, we will continue to show the post in the Published list instead of
    /// the Drafts list. We believe this behavior is less confusing for the user.
    ///
    /// This is not meant to be up to date with the remote API. Eventually, this information will
    /// be outdated. For example, the user could have changed the status in the web while the device
    /// was offline. So we wouldn't recommend using this value aside from its original intention.
    ///
    /// - SeeAlso: PostService
    /// - SeeAlso: PostListFilter
    var statusAfterSync: Status? {
        get {
            return rawValue(forKey: "statusAfterSync")
        }
        set {
            setRawValue(newValue, forKey: "statusAfterSync")
        }
    }

    /// The string value of `statusAfterSync` based on `BasePost.Status`.
    ///
    /// This should only be used in Objective-C. For Swift, use `statusAfterSync`.
    ///
    /// - SeeAlso: statusAfterSync
    @objc(statusAfterSync)
    var statusAfterSyncString: String? {
        get {
            return statusAfterSync?.rawValue
        }
        set {
            statusAfterSync = newValue.flatMap { Status(rawValue: $0) }
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

    // MARK: - Misc

    /// Represent the supported properties used to sort posts.
    ///
    enum SortField {
        case dateCreated
        case dateModified

        /// The keyPath to access the underlying property.
        ///
        var keyPath: String {
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

    @objc func containsStoriesBlocks() -> Bool {
        return content?.contains("<!-- wp:jetpack/story") ?? false
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

    @objc override open func featuredImageURLForDisplay() -> URL? {
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

    var isEmpty: Bool {
        let title = (postTitle ?? "").trimmingCharacters(in: .whitespaces)
        let content = (content ?? "").trimmingCharacters(in: .whitespaces)
        return title.isEmpty && content.isEmpty
    }

    // TODO: Replace with a new flag
    @objc var isSyncNeeded: Bool {
        get { confirmedChangesHash == AbstractPost.syncNeededKey }
        set { confirmedChangesHash = newValue ? AbstractPost.syncNeededKey : "" }
    }

    static let syncNeededKey = "sync-needed"

    /// Returns the latest saved revisions that needs to be synced with the server.
    /// Returns `nil` if there are no such revisions.
    func getLatestRevisionNeedingSync() -> AbstractPost? {
        assert(original == nil, "Must be called on an original revision")
        var revision = self
        var current = self
        while let next = current.revision {
            if next.isSyncNeeded {
                revision = next
            }
            current = next
        }
        guard revision != self else {
            return nil
        }
        return revision
    }

    /// Deletes all of the synced revisions until and including the `latest`
    /// one passed as a parameter.
    func deleteSyncedRevisions(until latest: AbstractPost) {
        assert(original == nil, "Must be called on an original revision")
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
}

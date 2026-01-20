import Foundation
import WordPressKit
import WordPressShared

public enum AbstractPostRemoteStatus: UInt {
    case pushing
    case failed
    case local
    case sync
    case pushingMedia
    case autoSaved
    case localRevision
    case syncNeeded
}

@objc(AbstractPost)
public class AbstractPost: BasePost {

    public var voiceContent: String?

    @objc public var revision: AbstractPost? {
        willAccessValue(forKey: "revision")
        let revision = primitiveValue(forKey: "revision") as? AbstractPost
        didAccessValue(forKey: "revision")
        return revision
    }

    public var original: AbstractPost? {
        willAccessValue(forKey: "original")
        let original = primitiveValue(forKey: "original") as? AbstractPost
        didAccessValue(forKey: "original")
        return original
    }

    public func hasCategories() -> Bool {
        return false
    }

    public func hasTags() -> Bool {
        return false
    }

    public func contentPreviewForDisplay() -> String? {
        mt_excerpt
    }
}

public extension AbstractPost {
    /// Returns the original post by navigating the entire list of revisions
    /// until it reaches the head.
    func getOriginal() -> AbstractPost {
        original?.getOriginal() ?? self
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

    /// Creates an array of tags by parsing a comma-separate list of tags.
    static func makeTags(from tags: String) -> [String] {
        tags
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Status

    /// Returns `true` is the post has one of the given statuses.
    func isStatus(in statuses: Set<Status>) -> Bool {
        statuses.contains(status ?? .draft)
    }

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

    func containsGutenbergBlocks() -> Bool {
        return content?.contains("<!-- wp:") ?? false
    }

    var analyticsUserInfo: [String: Any] {
        [
            "post_type": analyticsPostType ?? "",
            "status": status?.rawValue ?? "",
            "original_status": getOriginal().status?.rawValue ?? "unknown",
            "password_protected": PostVisibility(post: self) == .protected
        ]
    }

    /// The post type as recorded in the `post_type` column of `wp_posts`
    ///
    var wpPostType: String {
        return switch self {
            case is Post: "post"
            case is Page: "page"
            default: preconditionFailure("Unknown post type")
        }
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

    func featuredImageURLForDisplay() -> URL? {
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
        let original = revision.getOriginal()
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

    func dateStringForDisplay() -> String? {
        if self.originalIsDraft() || self.status == .pending {
            return dateModified?.toMediumString()
        } else if self.status == .scheduled {
            return self.dateCreated?.mediumStringWithTime()
        } else if self.shouldPublishImmediately() {
            return NSLocalizedString("Publish Immediately", comment: "A short phrase indicating a post is due to be immedately published.")
        }
        return self.dateCreated?.toMediumString()
    }

    func clone(from source: AbstractPost) {
        for key in source.entity.attributesByName.keys {
            if key != "permalink" {
                setValue(source.value(forKey: key), forKey: key)
            }
        }

        for key in source.entity.relationshipsByName.keys {
            if key == "original" || key == "revision" {
                continue
            } else if key == "comments" {
                comments = source.comments
            } else {
                setValue(source.value(forKey: key), forKey: key)
            }
        }
    }

    func createRevision() -> AbstractPost {
        precondition(managedObjectContext != nil)
        precondition(revision == nil, "This post must not already have a revision")

        let post = Self(context: managedObjectContext!)
        post.clone(from: self)
        post.remoteStatus = .localRevision
        post.setValue(self, forKey: "original")
        post.setValue(nil, forKey: "revision")
        return post
    }

    func deleteRevision() {
        guard let revision, let context = managedObjectContext else {
            return
        }

        context.performAndWait {
            context.delete(revision)
            willChangeValue(forKey: "revision")
            setPrimitiveValue(nil, forKey: "revision")
            didChangeValue(forKey: "revision")
        }
    }

    func applyRevision() {
        guard isOriginal(), let revision else {
            return
        }
        clone(from: revision)
    }

    func isRevision() -> Bool {
        !isOriginal()
    }

    func isOriginal() -> Bool {
        original == nil
    }

    func latest() -> AbstractPost {
        revision?.latest() ?? self
    }

    func hasRevision() -> Bool {
        revision != nil
    }

    /// Returns YES if the original post is a draft
    func originalIsDraft() -> Bool {
        if status == .draft {
            return true
        } else if isRevision(), original?.status == .draft {
            return true
        }
        return false
    }

    func shouldPublishImmediately() -> Bool {
        // - warning: Yes, this is WordPress logic and it matches the behavior on
        // the web. If `dateCreated` is the same as `dateModified`, the system
        // uses it to represent a "no publish date selected" scenario.
        originalIsDraft() && (date_created_gmt == nil || date_created_gmt == dateModified)
    }

    /// Does the post exist on the blog?
    func hasRemote() -> Bool {
        (postID?.int64Value ?? 0) > 0
    }

    @objc
    var parsedOtherTerms: [String: [String]] {
        get {
            guard let rawOtherTerms else {
                return [:]
            }

            return (try? JSONSerialization.jsonObject(with: rawOtherTerms) as? [String: [String]]) ?? [:]
        }
        set {
            rawOtherTerms = try? JSONSerialization.data(withJSONObject: newValue)
        }
    }

    /// Updates the path for the display image by looking at the post content and trying to find an good image to use.
    /// If no appropiated image is found the path is set to nil.
    @objc
    func updatePathForDisplayImageBasedOnContent() {
        guard let content else {
            return
        }

        if let result = DisplayableImageHelper.searchPostContentForImage(toDisplay: content), !result.isEmpty {
            pathForDisplayImage = result
            return
        }

        guard let allMedia = blog.media, !allMedia.isEmpty else { return }

        let mediaIDs = DisplayableImageHelper.searchPostContentForAttachmentIds(inGalleries: content) as? Set<NSNumber> ?? []
        for media in allMedia {
            guard let media = media as? Media else { continue }

            guard let mediaID = media.mediaID,
                  mediaIDs.contains(mediaID) else {
                continue
            }

            if let remoteURL = media.remoteURL {
                pathForDisplayImage = remoteURL
                break
            }
        }
    }
}

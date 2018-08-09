import Foundation
import CoreData
import CocoaLumberjack
import WordPressKit

// MARK: - Notification Entity
//
@objc(Notification)
class Notification: NSManagedObject {
    /// Notification Primary Key!
    ///
    @NSManaged var notificationId: String

    /// Notification Hash!
    ///
    @NSManaged var notificationHash: String?

    /// Indicates whether the note was already read, or not
    ///
    @NSManaged var read: Bool

    /// Associated Resource's Icon, as a plain string
    ///
    @NSManaged var icon: String?

    /// Noticon resource, associated with this notification
    ///
    @NSManaged var noticon: String?

    /// Timestamp as a String
    ///
    @NSManaged var timestamp: String?

    /// Notification Type
    ///
    @NSManaged var type: String?

    /// Associated Resource's URL
    ///
    @NSManaged var url: String?

    /// Plain Title ("1 Like" / Etc)
    ///
    @NSManaged var title: String?

    /// Raw Subject Blocks
    ///
    @NSManaged var subject: [AnyObject]?

    /// Raw Header Blocks
    ///
    @NSManaged var header: [AnyObject]?

    /// Raw Body Blocks
    ///
    @NSManaged var body: [AnyObject]?

    /// Raw Associated Metadata
    ///
    @NSManaged var meta: [String: AnyObject]?

    /// Timestamp As Date Transient Storage.
    ///
    fileprivate var cachedTimestampAsDate: Date?

    let formatter = FormattableContentFormatter()

    /// Subject Blocks Transient Storage.
    ///
    fileprivate var cachedSubjectBlockGroup: NotificationBlockGroup?
    fileprivate var cachedSubjectContentGroup: FormattableContentGroup?

    /// Header Blocks Transient Storage.
    ///
    fileprivate var cachedHeaderBlockGroup: NotificationBlockGroup?
    fileprivate var cachedHeaderContentGroup: FormattableContentGroup?

    /// Body Blocks Transient Storage.
    ///
    fileprivate var cachedBodyBlockGroups: [NotificationBlockGroup]?
    fileprivate var cachedBodyContentGroups: [FormattableContentGroup]?

    /// Header + Body Blocks Transient Storage.
    ///
    fileprivate var cachedHeaderAndBodyBlockGroups: [NotificationBlockGroup]?
    fileprivate var cachedHeaderAndBodyContentGroups: [FormattableContentGroup]?

    /// Array that contains the Cached Property Names
    ///
    fileprivate static let cachedAttributes = Set(arrayLiteral: "body", "header", "subject", "timestamp")

    func renderSubject() -> NSAttributedString? {
        guard let subjectContent = subjectContentGroup?.blocks.first else {
            return nil
        }
        return formatter.render(content: subjectContent, with: SubjectContentStyles())
    }

    func renderSnippet() -> NSAttributedString? {
        guard let snippetContent = snippetContent else {
            return nil
        }
        return formatter.render(content: snippetContent, with: SnipetsContentStyles())
    }

    /// When needed, nukes cached attributes
    ///
    override func willChangeValue(forKey key: String) {
        super.willChangeValue(forKey: key)

        // Note:
        // Cached Attributes are only consumed on the main thread, when initializing UI elements.
        // As an optimization, we'll only reset those attributes when we're running on the main thread.
        //
        guard managedObjectContext?.concurrencyType == .mainQueueConcurrencyType else {
            return
        }

        guard Swift.type(of: self).cachedAttributes.contains(key) else {
            return
        }

        resetCachedAttributes()
    }

    /// Nukes any cached values.
    ///
    func resetCachedAttributes() {
        cachedTimestampAsDate = nil

        if FeatureFlag.extractNotifications.enabled {
            formatter.resetCache()
            cachedBodyContentGroups = nil
            cachedHeaderContentGroup = nil
            cachedSubjectContentGroup = nil
            cachedHeaderAndBodyContentGroups = nil
        } else {
            cachedSubjectBlockGroup = nil
            cachedHeaderBlockGroup = nil
            cachedBodyBlockGroups = nil
            cachedHeaderAndBodyBlockGroups = nil
        }
    }

    // This is a NO-OP that will force NSFetchedResultsController to reload the row for this object.
    // Helpful when dealing with transient attributes.
    //
    @objc func didChangeOverrides() {
        let readValue = read
        read = readValue
    }

    /// Returns the first BlockGroup of the specified type, if any.
    ///
    func contentGroup(ofKind kind: FormattableContentGroup.Kind) -> FormattableContentGroup? {
        for contentGroup in bodyContentGroups where contentGroup.kind == kind {
            return contentGroup
        }

        return nil
    }

    /// Returns the first BlockGroup of the specified type, if any.
    ///
    func blockGroupOfKind(_ kind: NotificationBlockGroup.Kind) -> NotificationBlockGroup? {
        for blockGroup in bodyBlockGroups where blockGroup.kind == kind {
            return blockGroup
        }

        return nil
    }

    /// Attempts to find the Notification Range associated with a given URL.
    ///
    func notificationRangeWithUrl(_ url: URL) -> NotificationRange? {
        var groups = bodyBlockGroups
        if let headerBlockGroup = headerBlockGroup {
            groups.append(headerBlockGroup)
        }

        let blocks = groups.flatMap { $0.blocks }
        for block in blocks {
            if let range = block.notificationRangeWithUrl(url) {
                return range
            }
        }

        return nil
    }

    /// Attempts to find the Notification Range associated with a given URL.
    ///
    func contentRange(with url: URL) -> FormattableContentRange? {
        var groups = bodyContentGroups
        if let headerBlockGroup = headerContentGroup {
            groups.append(headerBlockGroup)
        }

        let blocks = groups.flatMap { $0.blocks }
        for block in blocks {
            if let range = block.range(with: url) {
                return range
            }
        }

        return nil
    }
}

// MARK: - Notification Computed Properties
//
extension Notification {

    /// Verifies if the current notification is a Pingback.
    ///
    var isPingback: Bool {
        if FeatureFlag.extractNotifications.enabled {
            guard subjectContentGroup?.blocks.count == 1 else {
                return false
            }
            guard let ranges = subjectContentGroup?.blocks.first?.ranges, ranges.count == 2 else {
                return false
            }
            return ranges.first?.kind == .site && ranges.last?.kind == .post
        } else {
            guard let subjectRanges = subjectBlock?.ranges, subjectRanges.count == 2 else {
                return false
            }

            return subjectRanges.first?.kind == .Site && subjectRanges.last?.kind == .Post
        }
    }

    /// Verifies if the current notification is actually a Badge one.
    /// Note: Sorry about the following snippet. I'm (and will always be) against Duck Typing.
    ///
    @objc var isBadge: Bool {
        if FeatureFlag.extractNotifications.enabled {
            let blocks = bodyContentGroups.flatMap { $0.blocks }
            for block in blocks where block is FormattableMediaContent {
                guard let mediaBlock = block as? FormattableMediaContent else {
                    continue
                }
                for media in mediaBlock.media where media.kind == .badge {
                    return true
                }
            }
            return false
        } else {
            let blocks = bodyBlockGroups.flatMap { $0.blocks }
            for block in blocks {
                for media in block.media where media.kind == .Badge {
                    return true
                }
            }

            return false
        }
    }

    /// Verifies if the current notification is a Comment-Y note, and if it has been replied to.
    ///
    @objc var isRepliedComment: Bool {
        return kind == .Comment && metaReplyID != nil
    }

    //// Check if this note is a comment and in 'Unapproved' status
    ///
    @objc var isUnapprovedComment: Bool {
        if FeatureFlag.extractNotifications.enabled {
            guard let block: FormattableCommentContent = contentGroup(ofKind: .comment)?.blockOfKind(.comment) else {
                return false
            }
            let commandId = ApproveCommentAction.actionIdentifier()
            return block.isActionEnabled(id: commandId) && !block.isActionOn(id: commandId)
        } else {
            guard let block = blockGroupOfKind(.comment)?.blockOfKind(.comment) else {
                return false
            }

            return block.isActionEnabled(.Approve) && !block.isActionOn(.Approve)
        }

    }

    var kind: Kind {
        guard let type = type, let kind = Kind(rawValue: type) else {
            return .Unknown
        }
        return kind
    }

    /// Parses the Notification.type field into a Swift Native enum. Returns .Unknown on failure.
    ///
    var notificationKind: Kind {
        guard let type = type, let kind = Kind(rawValue: type) else {
            return .Unknown
        }
        return kind
    }

    /// Returns the Meta ID's collection, if any.
    ///
    fileprivate var metaIds: [String: AnyObject]? {
        return meta?[MetaKeys.Ids] as? [String: AnyObject]
    }

    /// Comment ID, if any.
    ///
    @objc var metaCommentID: NSNumber? {
        return metaIds?[MetaKeys.Comment] as? NSNumber
    }

    /// Post ID, if any.
    ///
    @objc var metaPostID: NSNumber? {
        return metaIds?[MetaKeys.Post] as? NSNumber
    }

    /// Comment Reply ID, if any.
    ///
    @objc var metaReplyID: NSNumber? {
        return metaIds?[MetaKeys.Reply] as? NSNumber
    }

    /// Site ID, if any.
    ///
    @objc var metaSiteID: NSNumber? {
        return metaIds?[MetaKeys.Site] as? NSNumber
    }

    /// Icon URL
    ///
    @objc var iconURL: URL? {
        guard let rawIconURL = icon, let iconURL = URL(string: rawIconURL) else {
            return nil
        }

        return iconURL
    }

    /// Associated Resource URL
    ///
    @objc var resourceURL: URL? {
        guard let rawURL = url, let resourceURL = URL(string: rawURL) else {
            return nil
        }

        return resourceURL
    }

    /// Parse the Timestamp as a Cocoa Date Instance.
    ///
    @objc var timestampAsDate: Date {
        assert(timestamp != nil, "Notification Timestamp should not be nil [\(notificationId)]")

        if let timestampAsDate = cachedTimestampAsDate {
            return timestampAsDate
        }

        guard let timestamp = timestamp, let timestampAsDate = Date.dateWithISO8601String(timestamp) else {
            DDLogError("Error: couldn't parse date [\(String(describing: self.timestamp))] for notification with id [\(notificationId)]")
            return Date()
        }

        cachedTimestampAsDate = timestampAsDate
        return timestampAsDate
    }

    var subjectContentGroup: FormattableContentGroup? {
        if let group = cachedSubjectContentGroup {
            return group
        }

        guard let subject = subject as? [[String: AnyObject]], subject.isEmpty == false else {
            return nil
        }

        cachedSubjectContentGroup = SubjectContentGroup.createGroup(from: subject, parent: self)
        return cachedSubjectContentGroup
    }

    /// Returns the Subject Block Group, if any.
    ///
    var subjectBlockGroup: NotificationBlockGroup? {
        if let subjectBlockGroup = cachedSubjectBlockGroup {
            return subjectBlockGroup
        }

        guard let subject = subject as? [[String: AnyObject]], subject.isEmpty == false else {
            return nil
        }

        cachedSubjectBlockGroup = NotificationBlockGroup.groupFromSubject(subject, parent: self)
        return cachedSubjectBlockGroup
    }

    var headerContentGroup: FormattableContentGroup? {
        if let group = cachedHeaderContentGroup {
            return group
        }

        guard let header = header as? [[String: AnyObject]], header.isEmpty == false else {
            return nil
        }

        cachedHeaderContentGroup = HeaderContentGroup.createGroup(from: header, parent: self)
        return cachedHeaderContentGroup
    }

    /// Returns the Header Block Group, if any.
    ///
    var headerBlockGroup: NotificationBlockGroup? {
        if let headerBlockGroup = cachedHeaderBlockGroup {
            return headerBlockGroup
        }

        guard let header = header as? [[String: AnyObject]], header.isEmpty == false else {
            return nil
        }

        cachedHeaderBlockGroup = NotificationBlockGroup.groupFromHeader(header, parent: self)
        return cachedHeaderBlockGroup
    }

    var bodyContentGroups: [FormattableContentGroup] {
        if let group = cachedBodyContentGroups {
            return group
        }

        guard let body = body as? [[String: AnyObject]], body.isEmpty == false else {
            return []
        }

        cachedBodyContentGroups = BodyContentGroup.create(from: body, parent: self)
        return cachedBodyContentGroups ?? []
    }

    /// Returns the Body Block Groups, if any.
    ///
    var bodyBlockGroups: [NotificationBlockGroup] {
        if let bodyBlockGroups = cachedBodyBlockGroups {
            return bodyBlockGroups
        }

        guard let body = body as? [[String: AnyObject]], body.isEmpty == false else {
            return []
        }

        cachedBodyBlockGroups = NotificationBlockGroup.groupsFromBody(body, parent: self)
        return cachedBodyBlockGroups ?? []
    }


    var headerAndBodyContentGroups: [FormattableContentGroup] {
        if let groups = cachedHeaderAndBodyContentGroups {
            return groups
        }

        var mergedGroups = [FormattableContentGroup]()
        if let header = headerContentGroup {
            mergedGroups.append(header)
        }

        mergedGroups.append(contentsOf: bodyContentGroups)
        cachedHeaderAndBodyContentGroups = mergedGroups

        return mergedGroups
    }
    /// Returns the Header + Body Block Groups, if any. This is done for convenience.
    ///
    var headerAndBodyBlockGroups: [NotificationBlockGroup] {
        if let headerAndBodyBlockGroups = cachedHeaderAndBodyBlockGroups {
            return headerAndBodyBlockGroups
        }

        var mergedGroups = [NotificationBlockGroup]()
        if let header = headerBlockGroup {
            mergedGroups.append(header)
        }

        mergedGroups.append(contentsOf: bodyBlockGroups)
        cachedHeaderAndBodyBlockGroups = mergedGroups

        return mergedGroups
    }

    /// Returns the Subject Block, if any.
    ///
    var subjectBlock: NotificationBlock? {
        return subjectBlockGroup?.blocks.first
    }

    var snippetContent: FormattableContent? {
        guard let content = subjectContentGroup?.blocks, content.count > 1 else {
            return nil
        }
        return content.last
    }

    /// Returns the Snippet Block, if any.
    ///
    var snippetBlock: NotificationBlock? {
        guard let subjectBlocks = subjectBlockGroup?.blocks, subjectBlocks.count > 1 else {
            return nil
        }

        return subjectBlocks.last
    }
}


// MARK: - Update Helpers
//
extension Notification {
    /// Updates the local fields with the new values stored in a given Remote Notification
    ///
    func update(with remote: RemoteNotification) {
        notificationId = remote.notificationId
        notificationHash = remote.notificationHash
        read = remote.read
        icon = remote.icon
        noticon = remote.noticon
        timestamp = remote.timestamp
        type = remote.type
        url = remote.url
        title = remote.title
        subject = remote.subject
        header = remote.header
        body = remote.body
        meta = remote.meta
    }
}

// MARK: - Notification Types
//
extension Notification {
    /// Known kinds of Notifications
    ///
    enum Kind: String {
        case Comment        = "comment"
        case CommentLike    = "comment_like"
        case Follow         = "follow"
        case Like           = "like"
        case Matcher        = "automattcher"
        case NewPost        = "new_post"
        case Post           = "post"
        case User           = "user"
        case Unknown        = "unknown"

        var toTypeValue: String {
            return rawValue
        }
    }

    /// Meta Parsing Keys
    ///
    fileprivate enum MetaKeys {
        static let Ids      = "ids"
        static let Links    = "links"
        static let Titles   = "titles"
        static let Site     = "site"
        static let Post     = "post"
        static let Comment  = "comment"
        static let Reply    = "reply_comment"
        static let Home     = "home"
    }
}

extension Notification: NotificationIdentifiable {
    var notificationIdentifier: String {
        return notificationId
    }
}

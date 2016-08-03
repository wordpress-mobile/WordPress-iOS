import Foundation
import CoreData
import Simperium



// MARK: - Notification Entity
//
@objc(Notification)
class Notification: SPManagedObject
{
    override func didTurnIntoFault() {
        //        timestampAsDate     = nil
        //        subjectBlockGroup   = nil
        //        headerBlockGroup    = nil
        //        bodyBlockGroups     = []
    }

    // This is a NO-OP that will force NSFetchedResultsController to reload the row for this object.
    // Helpful when dealing with transient attributes.
    //
    func didChangeOverrides() {
        let readValue = read
        read = readValue
    }

    ///
    ///
    func blockGroupOfType(type: NoteBlockGroupType) -> NotificationBlockGroup? {
        for blockGroup in bodyBlockGroups where blockGroup.type == type {
            return blockGroup
        }

        return nil
    }

    /// Find in the header as well!
    ///
    func notificationRangeWithUrl(url: NSURL) -> NotificationRange? {
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
}



// MARK: - Notification Computed Properties
//
extension Notification
{
    ///
    ///
    enum Kind: String {
        case Comment        = "comment"
        case CommentLike    = "comment_like"
        case Follow         = "follow"
        case Like           = "like"
        case Matcher        = "automattcher"
        case Post           = "post"
        case User           = "user"
        case Unknown        = "unknown"

        var toTypeValue: String {
            return rawValue
        }
    }

    ///
    ///
    private enum MetaKeys {
        static let Ids      = "ids"
        static let Site     = "site"
        static let Post     = "post"
        static let Comment  = "comment"
        static let Reply    = "reply_comment"
    }

    ///
    ///
    var isBadge: Bool {
        //  Note: This developer does not like duck typing. Sorry about the following snippet.
        //
        let blocks = bodyBlockGroups.flatMap { $0.blocks }
        for block in blocks {
            for media in block.media where media.isBadge {
                return true
            }
        }

        return false
    }

    //// Check if this note is a comment and in 'Unapproved' status
    ///
    var isUnapprovedComment: Bool {
        guard let block = blockGroupOfType(.Comment)?.blockOfType(.Comment) else {
            return false
        }

        return block.isActionEnabled(.Approve) && !block.isActionOn(.Approve)
    }

    ///
    ///
    var isRepliedComment: Bool {
        return isComment == true && metaReplyID != nil
    }

    ///
    ///
    var kind: Kind {
        guard let type = type, let kind = Kind(rawValue: type) else {
            return .Unknown
        }
        return kind
    }


    // TODO: Nuke when NotificationBlock is Swifted
    var isComment: Bool {
        return kind == .Comment
    }

    // TODO: Nuke when NotificationBlock is Swifted
    var isCommentLike: Bool {
        return kind == .CommentLike
    }

    // TODO: Nuke when NotificationBlock is Swifted
    var isFollow: Bool {
        return kind == .Follow
    }

    // TODO: Nuke when NotificationBlock is Swifted
    var isLike: Bool {
        return kind == .Like
    }

    // TODO: Nuke when NotificationBlock is Swifted
    var isMatcher: Bool {
        return kind == .Matcher
    }

    // TODO: Nuke when NotificationBlock is Swifted
    var isPost: Bool {
        return kind == .Post
    }

    ///
    ///
    private var metaIds: [String: AnyObject]? {
        return meta?[MetaKeys.Ids] as? [String: AnyObject]
    }

    ///
    ///
    var metaCommentID: NSNumber? {
        return metaIds?[MetaKeys.Comment] as? NSNumber
    }

    ///
    ///
    var metaPostID: NSNumber? {
        return metaIds?[MetaKeys.Post] as? NSNumber
    }

    ///
    ///
    var metaReplyID: NSNumber? {
        return metaIds?[MetaKeys.Reply] as? NSNumber
    }

    ///
    ///
    var metaSiteID: NSNumber? {
        return metaIds?[MetaKeys.Site] as? NSNumber
    }

// CACHE PLEASE
    ///
    ///
    var iconURL: NSURL? {
        guard let rawIconURL = icon, let iconURL = NSURL(string: rawIconURL) else {
            return nil
        }

        return iconURL
    }

    ///
    ///
    var resourceURL: NSURL? {
        guard let rawURL = url, let resourceURL = NSURL(string: rawURL) else {
            return nil
        }

        return resourceURL
    }


    /// If, for whatever reason, the date cannot be parsed, make sure we always return a date.
    ///
    var timestampAsDate: NSDate {
        assert(timestamp != nil, "Notification Timestamp should not be nil [\(simperiumKey)]")

        guard let timestamp = timestamp, let date = NSDate.dateWithISO8601String(timestamp) else {
            DDLogSwift.logError("Error: couldn't parse date [\(self.timestamp)] for notification with id [\(simperiumKey)]")
            return NSDate()
        }

        return date
    }

    ///
    ///
    var subjectBlockGroup: NotificationBlockGroup? {
        guard let subject = subject, let groups = NotificationBlockGroup.blockGroupsFromArray(subject, notification: self) else {
            return nil
        }

        return groups.first
    }

    ///
    ///
    var headerBlockGroup: NotificationBlockGroup? {
        guard let header = header, let groups = NotificationBlockGroup.blockGroupsFromArray(header, notification: self) else {
            return nil
        }

        return groups.first
    }

    ///
    ///
    var bodyBlockGroups: [NotificationBlockGroup] {
        guard let body = body, let groups = NotificationBlockGroup.blockGroupsFromArray(body, notification: self) else {
            return []
        }

        return groups
    }

    ///
    ///
    var subjectBlock: NotificationBlock? {
        return subjectBlockGroup?.blocks.first
    }

    ///
    ///
    var snippetBlock: NotificationBlock? {
        guard let subjectBlocks = subjectBlockGroup?.blocks where subjectBlocks.count > 1 else {
            return nil
        }

        return subjectBlocks.last
    }
}

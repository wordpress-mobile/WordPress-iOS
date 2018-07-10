import Foundation

public enum ParentKind: String {
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

public protocol FormattableContentParent: AnyObject {
    var metaCommentID: NSNumber? { get }
    var uniqueID: String? { get }
    var kind: ParentKind { get }
    var metaReplyID: NSNumber? { get }
    var isPingback: Bool { get }
    func didChangeOverrides()
    func isEqual(to other: FormattableContentParent) -> Bool
}

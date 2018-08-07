
public class NotificationCommentRange: NotificationContentRange {
    public let commentID: NSNumber?

    public init(commentID: NSNumber?, properties: Properties) {
        self.commentID = commentID
        super.init(kind: .comment, properties: properties)
    }
}

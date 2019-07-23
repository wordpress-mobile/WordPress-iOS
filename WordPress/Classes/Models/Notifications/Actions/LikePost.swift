/// Encapsulates logic to Like a Post
final class LikePost: DefaultNotificationActionCommand {
    override var actionTitle: String {
        return NSLocalizedString("Like", comment: "Like a post.")
    }

    override func execute<ContentType: FormattableCommentContent>(context: ActionContext<ContentType>) {

    }
}

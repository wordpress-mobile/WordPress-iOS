/// Encapsulates logic to Like a Post
final class LikePost: DefaultNotificationActionCommand {
    override var actionTitle: String {
        return NSLocalizedString("Like", comment: "Like a post.")
    }

    func execute(context: ActionContext<FormattableCommentContent>) {

    }
}

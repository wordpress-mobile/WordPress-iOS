/// Encapsulates logic to Like a Post
final class LikePost: DefaultNotificationActionCommand {
    override var actionTitle: String {
        return NSLocalizedString("Like", comment: "Like a post.")
    }

    override func execute<ContentType: FormattableContent>(context: ActionContext<ContentType>) {
        guard let _ = context.block as? FormattableCommentContent else {
            super.execute(context: context)
            return
        }
    }
}

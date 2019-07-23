/// Encapsulates logic to Like a Post
final class LikePost: DefaultNotificationActionCommand {
    override func action(handler: @escaping UIContextualAction.Handler) -> UIContextualAction? {
        let action = UIContextualAction(style: .normal,
                                        title: NSLocalizedString("Like", comment: "Like a post."),
                                        handler: handler)
        action.backgroundColor = .primary
        return action
    }

    override func execute<ContentType: FormattableCommentContent>(context: ActionContext<ContentType>) {

    }
}

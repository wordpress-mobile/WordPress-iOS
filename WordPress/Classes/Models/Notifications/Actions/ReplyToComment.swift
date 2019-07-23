import MGSwipeTableCell

/// Encapsulates logic to reply to a comment
class ReplyToComment: DefaultNotificationActionCommand {
    static let title = NSLocalizedString("Reply", comment: "Reply to a comment.")
    static let hint = NSLocalizedString("Replies to a comment.", comment: "VoiceOver accessibility hint, informing the user the button can be used to reply to a comment.")

    override func action(handler: @escaping UIContextualAction.Handler) -> UIContextualAction? {
        let action = UIContextualAction(style: .normal,
                                        title: ReplyToComment.title, handler: handler)
        action.backgroundColor = .primary
        return action
    }

    override func execute<ContentType: FormattableCommentContent>(context: ActionContext<ContentType>) {
        let block = context.block
        let content = context.content
        actionsService?.replyCommentWithBlock(block, content: content, completion: { success in
            guard success else {
                context.completion?(nil, false)
                return
            }

            context.completion?(nil, true)
        })
    }
}

import MGSwipeTableCell

/// Encapsulates logic to reply to a comment
final class ReplyToComment: DefaultNotificationActionCommand {
    let replyIcon: UIButton = {
        let title = NSLocalizedString("Reply", comment: "Reply to a comment.")
        return MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
    }()

    override var icon: UIButton? {
        return replyIcon
    }

    override func execute(context: ActionContext) {
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

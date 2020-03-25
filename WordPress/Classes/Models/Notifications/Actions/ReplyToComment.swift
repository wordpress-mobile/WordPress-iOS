/// Encapsulates logic to reply to a comment
class ReplyToComment: DefaultNotificationActionCommand {
    static let title = NSLocalizedString("Reply", comment: "Reply to a comment.")
    static let hint = NSLocalizedString("Replies to a comment.", comment: "VoiceOver accessibility hint, informing the user the button can be used to reply to a comment.")

    override var actionTitle: String {
        return ReplyToComment.title
    }

    func execute(context: ActionContext<FormattableCommentContent>) {
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

/// Encapsulates logic to reply to a comment
class ReplyToComment: DefaultNotificationActionCommand {
    static let title = AppLocalizedString("Reply", comment: "Reply to a comment.")
    static let hint = AppLocalizedString("Replies to a comment.", comment: "VoiceOver accessibility hint, informing the user the button can be used to reply to a comment.")
    static let identifier = "reply-button"

    override var actionTitle: String {
        return ReplyToComment.title
    }

    override func execute<ContentType: FormattableContent>(context: ActionContext<ContentType>) {
        guard let block = context.block as? FormattableCommentContent else {
            super.execute(context: context)
            return
        }
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

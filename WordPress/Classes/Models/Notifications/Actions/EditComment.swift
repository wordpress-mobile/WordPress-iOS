/// Encapsulates logic to Edit a comment
class EditComment: DefaultNotificationActionCommand {
    static let title = NSLocalizedString("Edit", comment: "Edits a Comment")
    static let hint = NSLocalizedString("Edits the comment.", comment: "VoiceOver accessibility hint, informing the user the button can be used to Edit the Comment.")

    override func action(handler: @escaping UIContextualAction.Handler) -> UIContextualAction? {
        let action = UIContextualAction(style: .normal,
                                        title: EditComment.title,
                                        handler: handler)
        action.backgroundColor = .primary
        return action
    }

    override func execute<ContentType: FormattableCommentContent>(context: ActionContext<ContentType>) {
        let block = context.block
        let content = context.content
        actionsService?.updateCommentWithBlock(block, content: content, completion: { success in
            guard success else {
                context.completion?(nil, false)
                return
            }

            context.completion?(nil, true)
        })
    }
}

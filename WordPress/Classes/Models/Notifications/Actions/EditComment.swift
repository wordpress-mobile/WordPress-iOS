/// Encapsulates logic to Edit a comment
class EditComment: DefaultNotificationActionCommand {
    static let title = NSLocalizedString("Edit", comment: "Edits a Comment")
    static let hint = NSLocalizedString("Edits the comment.", comment: "VoiceOver accessibility hint, informing the user the button can be used to Edit the Comment.")

    override var actionTitle: String {
        return EditComment.title
    }

    override func execute<ContentType: FormattableContent>(context: ActionContext<ContentType>) {
        guard let block = context.block as? FormattableCommentContent else {
            super.execute(context: context)
            return
        }
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

import MGSwipeTableCell

/// Encapsulates logic to Edit a comment
final class EditComment: DefaultNotificationActionCommand {
    let editIcon: UIButton = {
        let title = NSLocalizedString("Edit", comment: "Edits a Comment")
        return MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
    }()

    override var icon: UIButton? {
        return editIcon
    }

    override func execute(context: ActionContext) {
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

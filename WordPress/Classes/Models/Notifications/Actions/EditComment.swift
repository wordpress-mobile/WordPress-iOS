import MGSwipeTableCell

/// Encapsulates logic to Edit a comment
class EditComment: DefaultNotificationActionCommand {
    static let title = NSLocalizedString("Edit", comment: "Edits a Comment")
    static let hint = NSLocalizedString("Edits the comment.", comment: "VoiceOver accessibility hint, informing the user the button can be used to Edit the Comment.")
    let editIcon: UIButton = {
        let button = MGSwipeButton(title: title, backgroundColor: .primary)
        button.accessibilityLabel = title
        button.accessibilityTraits = UIAccessibilityTraits.button
        button.accessibilityHint = hint
        return button
    }()

    override var icon: UIButton? {
        return editIcon
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

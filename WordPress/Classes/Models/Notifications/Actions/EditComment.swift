import MGSwipeTableCell

/// Encapsulates logic to Edit a comment
final class EditComment: DefaultNotificationActionCommand {
    let editIcon: UIButton = {
        let title = NSLocalizedString("Edit", comment: "Edits a Comment")
        let button = MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
        button.accessibilityLabel = title
        button.accessibilityTraits = UIAccessibilityTraitButton
        button.accessibilityHint = NSLocalizedString("Edits a comment.", comment: "VoiceOver accessibility hint, informing the user the button can be used to Edit a Comment.")
        return button
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

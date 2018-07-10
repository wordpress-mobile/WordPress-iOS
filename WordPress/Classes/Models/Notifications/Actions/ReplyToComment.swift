import MGSwipeTableCell

/// Encapsulates logic to reply to a comment
final class ReplyToComment: DefaultNotificationActionCommand {
    let replyIcon: UIButton = {
        let title = NSLocalizedString("Reply", comment: "Reply to a comment.")
        let button = MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
        button.accessibilityLabel = title
        button.accessibilityTraits = UIAccessibilityTraitButton
        button.accessibilityHint = NSLocalizedString("Replies to a comment.", comment: "VoiceOver accessibility hint, informing the user the button can be used to reply to a comment.")
        return button
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

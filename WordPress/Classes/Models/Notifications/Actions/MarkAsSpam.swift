import MGSwipeTableCell

/// Encapsulates logic to mark a comment as spam
final class MarkAsSpam: DefaultNotificationActionCommand {
    let spamIcon: UIButton = {
        let title = NSLocalizedString("Spam", comment: "Marks comment as spam.")
        let button = MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
        button.accessibilityLabel = title
        button.accessibilityTraits = UIAccessibilityTraitButton
        button.accessibilityHint = NSLocalizedString("Mark as spam.", comment: "VoiceOver accessibility hint, informing the user the button can be used to reply Mark a comment as spam.")
        return button
    }()

    override var icon: UIButton? {
        return spamIcon
    }

    override func execute(context: ActionContext) {
        let request = NotificationDeletionRequest(kind: .spamming, action: { [weak self] requestCompletion in
            self?.actionsService?.spamCommentWithBlock(context.block) { (success) in
                requestCompletion(success)
            }
        })
        context.completion?(request, true)
    }
}

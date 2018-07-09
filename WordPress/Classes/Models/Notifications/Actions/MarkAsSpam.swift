import MGSwipeTableCell

final class MarkAsSpam: DefaultNotificationActionCommand {
    let spamIcon: UIButton = {
        let title = NSLocalizedString("Spam", comment: "Mark s comment as spam.")
        return MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
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

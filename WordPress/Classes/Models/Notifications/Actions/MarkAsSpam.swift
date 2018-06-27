import MGSwipeTableCell

final class MarkAsSpam: DefaultNotificationAction {
    let spamIcon: UIButton = {
        let title = NSLocalizedString("Spam", comment: "Mark s comment as spam.")
        return MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
    }()

    override var icon: UIButton? {
        return spamIcon
    }

    func execute(block: NotificationBlock, onCompletion: ((NotificationDeletionRequest) -> Void)? = nil) {
        let request = NotificationDeletionRequest(kind: .spamming, action: { [weak self] requestCompletion in
            self?.actionsService?.spamCommentWithBlock(block) { (success) in
                requestCompletion(success)
            }
        })
        onCompletion?(request)
    }
}

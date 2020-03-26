/// Encapsulates logic to mark a comment as spam
class MarkAsSpam: DefaultNotificationActionCommand {
    static let title = NSLocalizedString("Spam", comment: "Marks comment as spam.")
    static let hint = NSLocalizedString("Mark as spam.", comment: "VoiceOver accessibility hint, informing the user the button can be used to Mark a comment as spam.")

    override var actionTitle: String {
        return MarkAsSpam.title
    }

    override func execute<ContentType: FormattableContent>(context: ActionContext<ContentType>) {
        guard let block = context.block as? FormattableCommentContent else {
            super.execute(context: context)
            return
        }
        let request = NotificationDeletionRequest(kind: .spamming, action: { [weak self] requestCompletion in
            self?.actionsService?.spamCommentWithBlock(block) { (success) in
                requestCompletion(success)
            }
        })
        context.completion?(request, true)
    }
}

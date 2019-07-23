/// Encapsulates logic to trash a comment
class TrashComment: DefaultNotificationActionCommand {
    static let title = NSLocalizedString("Trash", comment: "Trashes the comment")
    static let hint = NSLocalizedString("Moves the comment to the Trash.", comment: "VoiceOver accessibility hint, informing the user the button can be used to Move a comment to the Trash.")

    override func action(handler: @escaping UIContextualAction.Handler) -> UIContextualAction? {
        // Not set to 'destructive' style as that immediately removes the cell on activation,
        // but we want to display our own undo cell in place.
        let action = UIContextualAction(style: .normal,
                                        title: TrashComment.title, handler: handler)
        action.backgroundColor = .error
        return action
    }

    override func execute<ContentType: FormattableCommentContent>(context: ActionContext<ContentType>) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            let request = NotificationDeletionRequest(kind: .deletion, action: { [weak self] requestCompletion in
                self?.actionsService?.deleteCommentWithBlock(context.block, completion: { success in
                    requestCompletion(success)
                })
            })

            context.completion?(request, true)
        }
    }
}

import MGSwipeTableCell

/// Encapsulates logic to trash a comment
class TrashComment: DefaultNotificationActionCommand {
    static let title = NSLocalizedString("Trash", comment: "Trashes the comment")
    static let hint = NSLocalizedString("Moves the comment to the Trash.", comment: "VoiceOver accessibility hint, informing the user the button can be used to Move a comment to the Trash.")

    let trashIcon: UIButton = {
        let button = MGSwipeButton(title: title, backgroundColor: .error)
        button.accessibilityLabel =  title
        button.accessibilityTraits = UIAccessibilityTraits.button
        button.accessibilityHint = hint
        return button
    }()

    override var icon: UIButton? {
        return trashIcon
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

import MGSwipeTableCell

final class TrashComment: DefaultNotificationAction {
    let trashIcon: UIButton = {
        let title = NSLocalizedString("Trash", comment: "Trashes a comment")
        return MGSwipeButton(title: title, backgroundColor: WPStyleGuide.errorRed())
    }()

    override var icon: UIButton? {
        return trashIcon
    }

    func execute(context: ActionContext) {
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

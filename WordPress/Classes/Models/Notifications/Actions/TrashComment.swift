import MGSwipeTableCell

final class TrashComment: DefaultNotificationAction {
    let trashIcon: UIButton = {
        let title = NSLocalizedString("Trash", comment: "Trashes a comment")
        return MGSwipeButton(title: title, backgroundColor: WPStyleGuide.errorRed())
    }()

    override var icon: UIButton? {
        return trashIcon
    }

    func execute(block: NotificationBlock, onCompletion: ((NotificationDeletionRequest) -> Void)?) {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            let request = NotificationDeletionRequest(kind: .deletion, action: { [weak self] requestCompletion in
                self?.actionsService?.deleteCommentWithBlock(block, completion: { success in
                    requestCompletion(success)
                })
            })

            onCompletion?(request)
        }
    }
}

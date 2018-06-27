import MGSwipeTableCell

final class LikeComment: DefaultNotificationAction {
    let likeIcon: UIButton = {
        let title = NSLocalizedString("Like", comment: "Like a comment.")
        return MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
    }()

    override var icon: UIButton? {
        return likeIcon
    }

    func execute(block: NotificationBlock, onCompletion: ((NotificationDeletionRequest) -> Void)?) {
        actionsService?.likeCommentWithBlock(block)
    }
}

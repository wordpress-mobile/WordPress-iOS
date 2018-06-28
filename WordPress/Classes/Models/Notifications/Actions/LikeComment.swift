import MGSwipeTableCell

final class LikeComment: DefaultNotificationAction {
    private enum TitleStrings {
        static let like = NSLocalizedString("Like", comment: "Likes a Comment")
        static let unlike = NSLocalizedString("Liked", comment: "A comment is marked as liked")
    }

    let likeIcon: UIButton = {
        let title = NSLocalizedString("Like", comment: "Like a comment.")
        return MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
    }()

    override var on: Bool {
        willSet {
            let newTitle = newValue ? TitleStrings.like : TitleStrings.unlike
            setIconTitle(newTitle)
        }
    }

    override var icon: UIButton? {
        return likeIcon
    }

    override func execute(context: ActionContext) {
        let block = context.block
        if on {
            removeLike(block: block)
        } else {
            like(block: block)
        }
    }

    private func like(block: NotificationBlock) {
        actionsService?.likeCommentWithBlock(block)
    }

    private func removeLike(block: NotificationBlock) {
        actionsService?.unlikeCommentWithBlock(block)
    }

    private func setIconTitle(_ title: String) {
        icon?.setTitle(title, for: .normal)
    }
}

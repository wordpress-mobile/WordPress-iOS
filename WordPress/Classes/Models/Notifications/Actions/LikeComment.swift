import MGSwipeTableCell
/// Encapsulates logic to Like a comment
final class LikeComment: DefaultNotificationActionCommand, AccessibleFormattableContentActionCommand {
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
            setIconStrings(title: newTitle, label: newTitle, hint: newTitle)
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

    private func like(block: ActionableObject) {
        actionsService?.likeCommentWithBlock(block)
    }

    private func removeLike(block: ActionableObject) {
        actionsService?.unlikeCommentWithBlock(block)
    }
}

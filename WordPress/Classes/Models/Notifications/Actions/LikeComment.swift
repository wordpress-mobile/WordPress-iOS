import MGSwipeTableCell
/// Encapsulates logic to Like a comment
class LikeComment: DefaultNotificationActionCommand, AccessibleFormattableContentActionCommand {
    enum TitleStrings {
        static let like = NSLocalizedString("Like", comment: "Likes a Comment")
        static let unlike = NSLocalizedString("Liked", comment: "A comment is marked as liked")
    }

    enum TitleHints {
        static let like = NSLocalizedString("Likes the Comment.", comment: "VoiceOver accessibility hint, informing the user the button can be used to like a comment")
        static let unlike = NSLocalizedString("Unlike the Comment.", comment: "VoiceOver accessibility hint, informing the user the button can be used to stop liking a comment")
    }

    let likeIcon: UIButton = {
        let title = TitleStrings.like
        let button = MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
        button.accessibilityLabel = title
        button.accessibilityTraits = UIAccessibilityTraitButton
        button.accessibilityHint = TitleHints.like
        return button
    }()

    override var on: Bool {
        willSet {
            let newTitle = newValue ? TitleStrings.like : TitleStrings.unlike
            let newHint = newValue ? TitleHints.like : TitleHints.unlike
            setIconStrings(title: newTitle, label: newTitle, hint: newHint)
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

        setIconStrings(title: TitleStrings.unlike,
                       label: TitleStrings.unlike,
                       hint: TitleHints.unlike)
    }

    private func removeLike(block: ActionableObject) {
        actionsService?.unlikeCommentWithBlock(block)

        setIconStrings(title: TitleStrings.like,
                       label: TitleStrings.like,
                       hint: TitleHints.like)
    }
}

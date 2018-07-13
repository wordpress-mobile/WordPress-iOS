import MGSwipeTableCell

/// Encapsulates logic to Like a Post
final class LikePost: DefaultNotificationActionCommand {
    let likeIcon: UIButton = {
        let title = NSLocalizedString("Like", comment: "Like a post.")
        let button = MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
        button.accessibilityLabel = title
        button.accessibilityTraits = UIAccessibilityTraitButton
        button.accessibilityHint = NSLocalizedString("Likes the post.", comment: "VoiceOver accessibility hint, informing the user the button can be used to Like a Post.")
        return button
    }()

    override var icon: UIButton? {
        return likeIcon
    }

    override func execute(context: ActionContext) {

    }
}

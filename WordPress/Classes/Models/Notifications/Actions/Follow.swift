import MGSwipeTableCell

/// Encapsulates logic to follow a blog
final class Follow: DefaultNotificationActionCommand {
    static let title = NSLocalizedString("Follow", comment: "Prompt to follow a blog.")
    static let hint = NSLocalizedString("Follows the blog.", comment: "VoiceOver accessibility hint, informing the user the button can be used to follow a blog.")
    static let selectedTitle = NSLocalizedString("Following", comment: "User is following the blog.")
    static let selectedHint = NSLocalizedString("Unfollows the blog.", comment: "VoiceOver accessibility hint, informing the user the button can be used to unfollow a blog.")

    let followIcon: UIButton = {
        let button = MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
        button.accessibilityLabel = title
        button.accessibilityTraits = UIAccessibilityTraitButton
        button.accessibilityHint = hint
        return button
    }()

    override var icon: UIButton? {
        return followIcon
    }

    override func execute<ContentType: FormattableUserContent>(context: ActionContext<ContentType>) {

    }
}

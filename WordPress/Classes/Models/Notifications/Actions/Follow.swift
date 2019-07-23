/// Encapsulates logic to follow a blog
final class Follow: DefaultNotificationActionCommand {
    static let title = NSLocalizedString("Follow", comment: "Prompt to follow a blog.")
    static let hint = NSLocalizedString("Follows the blog.", comment: "VoiceOver accessibility hint, informing the user the button can be used to follow a blog.")
    static let selectedTitle = NSLocalizedString("Following", comment: "User is following the blog.")
    static let selectedHint = NSLocalizedString("Unfollows the blog.", comment: "VoiceOver accessibility hint, informing the user the button can be used to unfollow a blog.")

    override func action(handler: @escaping UIContextualAction.Handler) -> UIContextualAction? {
        let action = UIContextualAction(style: .normal,
                                        title: Follow.title,
                                        handler: handler)
        action.backgroundColor = on ? .neutral(shade: .shade30) : .primary
        return action
    }

    override func execute<ContentType: FormattableUserContent>(context: ActionContext<ContentType>) {

    }
}

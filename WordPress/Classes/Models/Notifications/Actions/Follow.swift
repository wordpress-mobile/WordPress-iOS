/// Encapsulates logic to follow a blog
final class Follow: DefaultNotificationActionCommand {
    static let title = NSLocalizedString("Follow", comment: "Prompt to follow a blog.")
    static let hint = NSLocalizedString("Follows the blog.", comment: "VoiceOver accessibility hint, informing the user the button can be used to follow a blog.")
    static let selectedTitle = NSLocalizedString("Following", comment: "User is following the blog.")
    static let selectedHint = NSLocalizedString("Unfollows the blog.", comment: "VoiceOver accessibility hint, informing the user the button can be used to unfollow a blog.")

    override var actionTitle: String {
        return Follow.title
    }

    override var actionColor: UIColor {
        return on ? .neutral(.shade30) : .primary
    }

    override func execute<ContentType: FormattableUserContent>(context: ActionContext<ContentType>) {

    }
}

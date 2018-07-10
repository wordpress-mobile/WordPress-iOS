import MGSwipeTableCell

/// Encapsulates logic to follow a blog
final class Follow: DefaultNotificationActionCommand {
    let followIcon: UIButton = {
        let title = NSLocalizedString("Follow", comment: "Prompt to follow a blog.")
        return MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
    }()

    override var icon: UIButton? {
        return followIcon
    }

    override func execute(context: ActionContext) {

    }
}

import MGSwipeTableCell

final class ReplyToComment: DefaultNotificationAction {
    let replyIcon: UIButton = {
        let title = NSLocalizedString("Reply", comment: "Reply to a comment.")
        return MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
    }()

    override var icon: UIButton? {
        return replyIcon
    }

    func execute() {

    }
}

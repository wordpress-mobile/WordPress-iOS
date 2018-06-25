import MGSwipeTableCell

final class MarkAsSpam: DefaultNotificationAction {
    let spamIcon: UIButton = {
        let title = NSLocalizedString("Spam", comment: "Mark s comment as spam.")
        return MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
    }()

    override var icon: UIButton? {
        return spamIcon
    }

    func execute() {

    }
}

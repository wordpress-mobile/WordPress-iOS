import MGSwipeTableCell

final class Follow: DefaultNotificationAction {
    let followIcon: UIButton = {
        let title = NSLocalizedString("Follow", comment: "Prompt to follow a blog.")
        return MGSwipeButton(title: title, backgroundColor: WPStyleGuide.wordPressBlue())
    }()

    override var icon: UIButton? {
        return followIcon
    }

    func execute(context: ActionContext) {

    }
}
